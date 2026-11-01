# First-time setup

Do this once per Azure subscription (sections 1-4) and once per person
(sections 5-6). Every value you collect goes into 1Password, never into a
file in the repo.

Tools: Nix and devenv. Everything else comes from the repo
(`nix run .#op`). For the Azure CLI (`az`) use
[Azure Cloud Shell](https://shell.azure.com) (in the browser, already
logged in, nothing to install) or install it on your machine; it is not in
the devenv shell because its nixpkgs build is currently broken.

## How secrets reach OpenTofu

```
.env.schema  op(op://azure-infra/<item>/<field>)   committed, references only
     |  Varlock + @varlock/1password-plugin (bunx, pinned version)
     |  login: 1Password desktop app (OP_ACCOUNT) or service account token
     v
environment of one tofu run   ARM_*, AWS_*, TF_VAR_*, TF_STATE_BUCKET
```

`.env` (git-ignored) only says how to log in to 1Password.

## 1. 1Password vault (and optionally a service account)

1. Create a vault named `azure-infra` (the name is in the `op://`
   references in `.env.schema` and in `TF_VAR_onepassword_vault`). Give
   access to everyone who will run `plan`/`apply`.
2. Local use, recommended: the 1Password desktop app. Settings > Developer
   > "Integrate with 1Password CLI". Varlock and the OpenTofu 1Password
   provider then log in as you, with biometric unlock.
3. CI or a machine without the desktop app: 1Password.com > Developer >
   Service Accounts > create one with **read and write** on `azure-infra`
   (write: OpenTofu stores the generated passwords). Vault access cannot be
   changed later. Save the `ops_...` token in another vault.

Write the account or token into `.env` (section 5) first: the setup
commands below use `nix run .#op`, which needs one of them too
(`op signin` with the desktop app, or `export OP_SERVICE_ACCOUNT_TOKEN=...`).

## 2. Azure service principal

In [Azure Cloud Shell](https://shell.azure.com) (Bash), or anywhere `az`
is installed:

```sh
az login                                   # not needed in Cloud Shell
az account list -o table                   # find the subscription id
az account set --subscription <subscription-id>
az ad sp create-for-rbac --name azure-infra-tofu \
  --role Contributor --scopes /subscriptions/<subscription-id>
```

The last command prints `appId`, `password` and `tenant`. Store them right
away (the password is shown once), with the 1Password app or, back in the
repo's devenv shell:

```sh
nix run .#op -- item create --vault azure-infra --category password \
  --title azure-service-principal \
  'subscription_id[text]=<subscription-id>' 'tenant_id[text]=<tenant>' \
  'client_id[text]=<appId>' 'client_secret[password]=<password>'
```

Typing secrets on a command line can leave them in shell history; the
1Password app (add custom fields by hand) is equally fine.

## 3. Hetzner Object Storage bucket for state

1. Hetzner Cloud Console > Object Storage > Create bucket. Pick a location
   (`fsn1`, `nbg1` or `hel1`; it must match `state.location` in
   `terranix/settings.nix`), visibility **Private**, a unique name.
2. Security > S3 credentials > Generate. Store them:

```sh
nix run .#op -- item create --vault azure-infra --category password \
  --title hetzner-s3-state \
  'access_key_id[text]=<access key>' 'secret_access_key[password]=<secret key>'
```

## 4. State passphrase and private settings

```sh
# 48 random characters; never edit this item afterwards
nix run .#op -- item create --vault azure-infra --category password \
  --title tofu-state-passphrase --generate-password='letters,digits,symbols,48'

# Private values that must not be in the public repo. The CIDR fields are
# comma-separated; leave one empty for "no access from the internet".
nix run .#op -- item create --vault azure-infra --category password \
  --title sql-server-settings \
  'state_bucket[text]=<bucket name>' \
  'rdp_source_cidrs[text]=<your public IP>/32' \
  'sql_source_cidrs[text]='
```

Find your public IP with `curl -4 ifconfig.me`.

## 5. Each person: how to log in to 1Password

Create `.env` at the repo root (git-ignored) with one of:

```sh
OP_ACCOUNT=<shorthand from `op account list`, e.g. my-team>   # desktop app
# or
OP_SERVICE_ACCOUNT_TOKEN=ops_...                                # service account
```

Then `devenv allow` once per checkout (after `devenv hook` in your shell
rc), and `env-check`: every line should be green, secrets redacted.

## 6. Each checkout: locks and first plan

The first time the repo is cloned with no lock files committed yet:

```sh
nix flake lock && nix run .#sync-locks
git add flake.lock dev/flake.lock devenv.yaml devenv.lock
check                       # lint, docs, offline tofu validate
plan                        # first contact with Azure, 1Password and the bucket
```

A first `plan` should show only `+` lines (about 16 resources). `apply`
takes roughly 15-25 minutes, most of it the SQL IaaS extension configuring
storage. Afterwards `tofu output` prints the public IP, and 1Password has
the two new login items.
