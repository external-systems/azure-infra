# Operations and maintenance

## Passwords

| Login | Where | Rotate |
|---|---|---|
| Windows `azureadmin` | 1Password `<name> Windows admin` | In 1Password, generate a new password on the item. Then `az vm user update -g rg-<name> -n vm-<name> -u azureadmin -p '<new>'` (or reset it in the portal: VM > Help > Reset password). OpenTofu ignores later password changes on purpose: Azure could only apply them by rebuilding the VM. |
| SQL `sqladmin` | 1Password `<name> SQL login` | Generate a new one on the item, then in SSMS: `ALTER LOGIN sqladmin WITH PASSWORD = '<new>';` |
| Azure service principal | 1Password `azure-service-principal` | `az ad sp credential reset --id <client_id>`, store the new password in `client_secret`. |
| Hetzner S3 keys | 1Password `hetzner-s3-state` | Generate new keys in the Hetzner console, update the item, delete the old keys. |
| State passphrase | 1Password `tofu-state-passphrase` | **Do not.** Rotating needs OpenTofu's key-migration (`fallback`) config; plan it as a change. |

Lost the admin password: reset it as above; nothing in OpenTofu changes.

## Updates

- **Windows and SQL Server patches**: the SQL IaaS extension installs them
  in the weekly window (`sql.autoPatching`, Sunday 02:00 for 60 minutes by
  default) and `patch_mode = AutomaticByOS` keeps Windows Update on. Expect
  a reboot in the window.
- **SQL Server cumulative updates** beyond what the window installs: RDP in
  and run the CU installer, or use Azure Update Manager.
- **OpenTofu, providers, terranix**: come from the flake pins. Bump in a pull request:
  `nix flake update org-pkgs && nix run .#sync-locks` (nixpkgs, OpenTofu,
  providers) or `nix flake update terranix`. Then `check` and `plan`: a pin
  bump should give **no changes**. If the plan changes, read the provider's
  changelog before applying.
- **Varlock and its 1Password plugin**: pinned in
  `flake-parts/terranix.nix`, `devenv.nix` (varlock) and `.env.schema`
  (plugin). Bump together.

## Costs

The monthly estimate, what changes it and how to save are in
[costs](costs.md). The real bill is in the portal: Cost Management,
filtered by resource group `rg-<name>` or tag `managed-by = azure-infra`.

- Stop paying for compute: `az vm deallocate -g rg-<name> -n vm-<name>`
  (disks and IP are still billed; a plain shutdown inside Windows is still
  billed). Start: `az vm start ...`. OpenTofu does not track power state.

## Backups

Not configured by this repo yet. Until it is, take regular native backups
(`BACKUP DATABASE ... TO DISK = 'F:\backup\...' WITH COMPRESSION, CHECKSUM`)
and copy them off the VM, or enable Azure Backup for SQL Server in Azure
VM in the portal. Adding `auto_backup` (needs a storage account) to
`azurerm_mssql_virtual_machine` is the natural next feature.

Disk snapshots are not database backups: restore-tested `.bak` files are.

## Looking around safely

Locally, in the devenv shell:

```sh
tofu output -raw public_ip       # outputs with IPs are sensitive (public CI logs)
tofu state list                  # everything OpenTofu manages
tofu state show azurerm_windows_virtual_machine.sql
az vm get-instance-view -g rg-<name> -n vm-<name> --query instanceView.statuses
```

Portal: Virtual machines > `vm-<name>`; "SQL virtual machines" shows the
IaaS extension's view (license, storage, patching).

## Drift

If someone changed something in the portal, `plan` shows it as a change
back to what the repo says. Either let `apply` undo the portal change
(Actions > Infrastructure > Run workflow), or copy the change into
`settings.nix` in a pull request so the repo matches. Never leave the two
different.

## CI

- The only GitHub secret is `OP_SERVICE_ACCOUNT_TOKEN`, once per
  environment. Rotate it by creating a new 1Password service account and
  replacing the secret (`gh secret set ... --env ...`), then deleting the
  old account.
- GitHub Actions logs and pull request comments are public. Sensitive values
  are redacted by OpenTofu; never add `TF_LOG` or `echo` of variables to a
  workflow.
