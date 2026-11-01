# Troubleshooting

First find **which phase** failed. The error text says which tool printed
it; fix it in that phase, never by deleting state.

| Phase | Printed by | Typical cause |
|---|---|---|
| 1. Nix evaluation | `error:` with a Nix trace, before anything runs | Typo in a `.nix` file, an unknown option, a failed assertion, a file not `git add`ed |
| 2. Loading secrets | `error: Varlock could not load ...` | 1Password locked, wrong account/token, item or field name differs from `.env.schema` |
| 3. `tofu init` | `Error: ... backend` | Bucket name/keys, Hetzner location, state passphrase |
| 4. `tofu plan` | `Error:` with a resource address | Azure login or permissions, quota, region/size not available |
| 5. `tofu apply` | `Error:` while creating/updating | Azure-side failures, SQL IaaS extension, timeouts |

Run `check` first: it catches phases 1 and most schema mistakes offline.
In CI, the failing job tells you the phase: `check` is phase 1, `plan`
phases 2-4, `apply` phase 5. Open the run, then the red step.

## GitHub Actions

- `plan` or `apply` fails at once with `OP_SERVICE_ACCOUNT_TOKEN is not
  set` / Varlock errors: the environment secret is missing or the service
  account lost vault access. See [GitHub setup](github-setup.md).
- `apply` shows "Waiting": it needs a reviewer to approve `azure-production`
  (Review deployments). That is normal.
- `apply` was skipped: the plan had no changes.
- `Saved plan is stale`: something changed after the plan. Run the workflow
  again (Actions > Infrastructure > Run workflow on `main`).
- Merge button disabled: `check` or `plan` is red or still running.
- A pull request from a fork shows skipped jobs: by design, forks never run
  this repo's CI.

## 1. Nix evaluation

- `The option 'azureInfra.sqlServer.foo' does not exist`: the option name
  is wrong; options and their descriptions are in `terranix/sql-server.nix`.
- `Failed assertions: - azureInfra.sqlServer.disks needs ...`: the message
  says what to fix.
- Change seems ignored / `path ... does not exist`: `git add` the file.
- `fmt` changed files: commit those changes; `check` fails until you do.

## 2. Loading secrets (Varlock / 1Password)

Run `env-check`: it shows every variable, redacted, with a red mark on the
one that failed.

- `could not resolve op://azure-infra/<item>/<field>`: the item or field
  label in 1Password differs from `.env.schema`. Labels are case-sensitive.
- Desktop app: the app must be running and unlocked, with Settings >
  Developer > "Integrate with 1Password CLI" on, and `OP_ACCOUNT` in `.env`
  set to an account from `op account list`.
- Service account: token in `.env` as `OP_SERVICE_ACCOUNT_TOKEN`, and the
  account must have access to the `azure-infra` vault (fixed at creation).
- `bunx` cannot download Varlock: needs internet access to the npm
  registry the first time.

## 3. `tofu init`

- `NoSuchBucket` / `AccessDenied`: `sql-server-settings/state_bucket` or
  the `hetzner-s3-state` keys are wrong, or `state.location` in
  `settings.nix` is not the bucket's location.
- `decryption failed for all provided methods`: the state was written with a
  different passphrase. Someone changed `tofu-state-passphrase`. Restore the
  old value from the item's history in 1Password (item > ... > Previous
  versions). Never delete the state to "fix" this.
- `Backend configuration changed`: run `tofu init -reconfigure` once.

## 4. `tofu plan`

- `AADSTS7000215: Invalid client secret` / `AADSTS700016`: service principal
  secret expired or ids swapped; see [operations](operations.md), rotate it.
- `AuthorizationFailed`: the service principal lacks Contributor on the
  subscription (`az role assignment list --assignee <client_id>`).
- `Error acquiring the state lock`: another plan/apply is running, or one
  crashed. Wait. If you are sure nobody else is running, `tofu force-unlock
  <lock id>`, only with the person's go-ahead.
- `Instance cannot be destroyed` (`prevent_destroy`): the change would delete
  the VM or a disk. See [making-changes](making-changes.md), "Anything that replaces the server".
- Unexpected changes nobody made: drift from the portal, see [operations](operations.md).

## 5. `tofu apply`

- `SkuNotAvailable` / `OperationNotAllowed ... quota`: the VM size is not
  offered in the region or the subscription's vCPU quota is too low.
  `az vm list-skus --location <region> --size <size> -o table`; request
  quota in the portal (Subscriptions > Usage + quotas).
- `MissingSubscriptionRegistration ... Microsoft.SqlVirtualMachine`: the
  provider registration failed; `az provider register --namespace
  Microsoft.SqlVirtualMachine`, wait for `Registered`, re-run.
- `azurerm_mssql_virtual_machine` fails or times out: the SQL IaaS extension
  could not configure storage. Check VM > Extensions + applications >
  `SqlIaasExtension` status in the portal. Re-running `apply` is safe; it
  retries what is left.
- Password rejected: Azure needs 12-123 characters with three of lower,
  upper, digit, symbol; `passwordLength` must stay at 16 or more.

## Recover a half-finished apply

OpenTofu saves state after each resource, so re-running `plan` shows only
what is left. Do not create things by hand in the portal "to help": they are
not in state and the next apply will conflict. If something already exists
in Azure but not in state, it needs `tofu import`; explain and get approval
first.

## Getting more detail

`TF_LOG=DEBUG plan` prints provider HTTP traffic. It can contain secrets:
never paste it anywhere public, and turn it off afterwards.
