# First-time setup

Do this once per Azure subscription (sections 1-3) and once per person
(sections 4-5). Every value you collect goes into 1Password, never into a
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
environment of one tofu run   ARM_*, TF_VAR_*, TF_STATE_STORAGE_ACCOUNT
```

`.env` (git-ignored) only says how to log in to 1Password.

## 1. 1Password vault (and optionally a service account)

1. Create a vault named `azure-infra` (the name is in the `op://`
   references in `.env.schema` and in `TF_VAR_onepassword_vault`). Give
   access to everyone who will run `plan`/`apply`.
2. Local use, recommended: the 1Password desktop app. Settings > Developer
   > "Integrate with 1Password CLI". Varlock and the OpenTofu 1Password
   provider then log in as you, with biometric unlock.
   On NixOS, install the app and CLI with the NixOS modules (see
   [1Password on NixOS](#1password-on-nixos) below), not from a plain
   package.
3. CI or a machine without the desktop app: 1Password.com > Developer >
   Service Accounts > create one with **read and write** on `azure-infra`
   (write: OpenTofu stores the generated passwords). Vault access cannot be
   changed later. Save the `ops_...` token in another vault.

### 1Password on NixOS

The desktop app only trusts a CLI that is setgid to the `onepassword-cli`
group. The NixOS modules install exactly that wrapper
(`/run/wrappers/bin/op`); the tofu wrapper and `env-check` use it when it
exists. In the machine's NixOS configuration:

```nix
{
  nixpkgs.config.allowUnfreePredicate = pkg:
    builtins.elem (lib.getName pkg) ["1password" "1password-cli"];

  programs = {
    _1password.enable = true; # op, as the setgid wrapper
    _1password-gui = {
      enable = true;
      polkitPolicyOwners = ["andrew"]; # your user: system-auth unlock
    };
  };
}
```

Then rebuild, start 1Password, sign in, and:

1. Settings > Security: "Unlock using system authentication" on (password
   prompt via polkit; fingerprint if `services.fprintd.enable = true` and
   enrolled).
2. Settings > Developer: "Integrate with 1Password CLI" on.
3. Test: `op vault list` (the app asks to authorize, then lists vaults),
   then `env-check` in the repo.

Do not also install `_1password-cli` in `home.packages` or
`environment.systemPackages`: an unwrapped `op` earlier on `PATH` fails
with "connecting to desktop app" errors.

Write the account or token into `.env` (section 4) first: the setup
commands below use `nix run .#op`, which needs one of them too
(`op signin` with the desktop app, or `export OP_SERVICE_ACCOUNT_TOKEN=...`).

## 2. Azure account and service principal

### No Azure account yet

1. Go to <https://azure.microsoft.com/free> and sign up with a Microsoft
   account (an existing Outlook/Hotmail address works, or create one). It
   asks for a phone number and a credit card for identity checks.
2. The sign-up creates a **tenant** (your directory) and a free-trial
   **subscription**. The trial has a spending limit and low quotas, so
   upgrade it right away: portal > Subscriptions > the subscription >
   **Upgrade** to Pay-As-You-Go. You keep any remaining free credit.
3. Optional but wise: Cost Management > Budgets > create a monthly budget
   with an email alert.
4. Check the vCPU quota in your region (Subscriptions > Usage + quotas,
   filter "Standard DSv5 Family vCPUs" and the region in `settings.nix`):
   the default server needs 4. Request more there if it shows less.

### Service principal and state storage

`scripts/azure-bootstrap.sh` does both in one go. In
[Azure Cloud Shell](https://shell.azure.com) (Bash):

```sh
curl -fsSL https://raw.githubusercontent.com/external-systems/azure-infra/main/scripts/azure-bootstrap.sh | bash
```

It registers the resource providers, creates resource group
`rg-azure-infra-state` with a GRS storage account (`tfstate<random>`,
container `tfstate`, blob versioning and 30-day soft delete), creates the
service principal `azure-infra-tofu` (Contributor on the subscription),
and prints the values to store. Running it again reuses the storage account
and rotates the service principal secret.

Store them right away (the secret is shown once), in the 1Password app or,
back in the repo's devenv shell:

```sh
nix run .#op -- item create --vault azure-infra --category password \
  --title azure-service-principal \
  'subscription_id[text]=<subscription_id>' 'tenant_id[text]=<tenant_id>' \
  'client_id[text]=<client_id>' 'client_secret[password]=<client_secret>'
```

Typing secrets on a command line can leave them in shell history; the
1Password app (add custom fields by hand) is equally fine.

## 3. State passphrase and private settings

```sh
# 48 random characters; never edit this item afterwards
nix run .#op -- item create --vault azure-infra --category password \
  --title tofu-state-passphrase --generate-password='letters,digits,symbols,48'

# Private values that must not be in the public repo. The CIDR fields are
# comma-separated; leave one empty for "no access from the internet".
nix run .#op -- item create --vault azure-infra --category password \
  --title sql-server-settings \
  'state_storage_account[text]=<state_storage_account>' \
  'rdp_source_cidrs[text]=<your public IP>/32' \
  'sql_source_cidrs[text]='
```

Find your public IP with `curl -4 ifconfig.me`.

## 4. Each person: how to log in to 1Password

Create `.env` at the repo root (git-ignored) with one of:

```sh
OP_ACCOUNT=<shorthand from `op account list`, e.g. my-team>   # desktop app
# or
OP_SERVICE_ACCOUNT_TOKEN=ops_...                                # service account
```

Then `devenv allow` once per checkout (after `devenv hook` in your shell
rc), and `env-check`: every line should be green, secrets redacted.

## 5. GitHub and the first apply

Lock files are committed. Do the [GitHub setup](github-setup.md) (service
accounts, environments, `main` ruleset). Then open a pull request (any
small change, or Actions > Infrastructure > Run workflow on `main`).

A first plan shows only `+` lines (about 17 resources). After the approval,
`apply` takes roughly 15-25 minutes, most of it the SQL IaaS extension
configuring storage. Afterwards 1Password has the two new login items; the
server's address is in `<name> Windows admin`.

Locally (optional, Andrew): `check`, then `plan` in the devenv shell.
