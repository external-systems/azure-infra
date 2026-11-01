---
name: azure-infra
description: "Explain, configure, change, maintain and debug the external-systems/azure-infra repo: one Windows Server 2019 VM running SQL Server 2019 Web edition on Azure, built with terranix (Nix) and OpenTofu, credentials in 1Password, encrypted state in a private Hetzner S3 bucket. Written for people new to Azure and infrastructure as code. Load for any question or change about this repo, the SQL server, its firewall, disks, size, passwords, costs, plan/apply output, errors, or the move from Rackspace."
---

# azure-infra

This repo builds exactly one server on Microsoft Azure: a Windows Server
2019 virtual machine with SQL Server 2019 **Web** edition, plus the network,
firewall and disks around it. Nobody clicks around in the Azure portal to
change it. The server is described in Nix files, OpenTofu compares that
description with what exists in Azure, and it makes Azure match.

The people using this skill may know nothing about Azure, Nix or OpenTofu.
Your job is to make a change safe for them: explain in plain words what a
change does, what it costs and what can break, make the edit, then walk
them through `plan` and `apply`. Never run `apply` yourself unless they
explicitly ask, and never skip reading the plan with them.

## The mental model (say this first to a newcomer)

```
settings.nix  --(Nix/terranix)-->  config.tf.json  --(OpenTofu)-->  Azure
 you edit                           generated                       real server
                                        |
                       state: what OpenTofu built last time
                       (encrypted, in a private Hetzner bucket)
```

1. **You edit Nix** (`terranix/settings.nix`, rarely `terranix/sql-server.nix`).
2. **`plan`** shows the difference between the files and Azure. Nothing
   changes yet.
3. **`apply`** shows the same plan and asks for `yes`, then changes Azure.

Every secret (Azure login, bucket keys, state passphrase, the server's
passwords) and every private value (bucket name, firewall IPs) lives in
1Password. [Varlock](https://varlock.dev) reads them through its 1Password
plugin, using `.env.schema`, each time OpenTofu runs. The repo is
**public**: no password, key, bucket name or IP address is ever committed.

## Where things are

| Path | What it is | Edit? |
|---|---|---|
| `terranix/settings.nix` | Name, region, VM size, SQL listener scope | Yes: most changes |
| `terranix/sql-server.nix` | Every Azure resource and every option, with descriptions | For new features |
| `terranix/state.nix` | Hetzner state backend and state encryption | Rarely |
| `.env.schema` | Varlock schema: every credential as an `op://` 1Password reference | When adding a secret or renaming an item |
| `terranix/load-secrets.nix` | Runs Varlock before each tofu command and passes the bucket to `init` | Rarely |
| `flake-parts/terranix.nix` | Wires it into the flake; OpenTofu + providers | Rarely |
| `dev/checks.nix` | Offline `tofu validate` run by `check` | Rarely |
| `documentation/` | Human docs site and slide deck | Keep in step |
| `.env` (git-ignored) | `OP_ACCOUNT` (desktop app) or `OP_SERVICE_ACCOUNT_TOKEN` | Never commit |

## Commands (run from the repo root, inside the devenv shell)

| Command | Does | Changes Azure? |
|---|---|---|
| `fmt` | Format and lint every file | No |
| `check` | Lint, docs build, offline `tofu validate` | No |
| `plan` | Init, then show what would change | No |
| `apply` | Init, plan, ask `yes`, change Azure | **Yes** |
| `tofu output` | Public/private IP, 1Password item ids | No |
| `tofu state list` | Every resource OpenTofu manages | No |
| `env-check` | Resolve `.env.schema` via 1Password, values redacted | No |
| `nix run .#op -- <args>` | 1Password CLI (setup, checks) | No |

Without the devenv shell: `nix run .#sql-server.plan`,
`nix run .#sql-server.apply`, `nix run .#tofu -- <args>`.

## Route the task

The detailed guides are the repo's documentation pages (one source for
people and agents), at `documentation/docs/guide/` from the repo root:

| The person wants to... | Read |
|---|---|
| Understand what Azure things exist and why (resource group, VNet, NSG, disks, SQL IaaS, Web edition licensing) | [documentation/docs/guide/azure-concepts.md](../../documentation/docs/guide/azure-concepts.md) |
| Set this up the first time (1Password, Azure service principal, Hetzner bucket, locks) | [documentation/docs/guide/first-time-setup.md](../../documentation/docs/guide/first-time-setup.md) |
| Change something (open RDP, resize, grow a disk, allow web servers, patch window, region) and read a plan | [documentation/docs/guide/making-changes.md](../../documentation/docs/guide/making-changes.md) |
| Keep it running (passwords, updates, costs, backups, upgrading pins) | [documentation/docs/guide/operations.md](../../documentation/docs/guide/operations.md) |
| Fix an error | [documentation/docs/guide/troubleshooting.md](../../documentation/docs/guide/troubleshooting.md) |
| Move the databases from the old Rackspace server | [documentation/docs/guide/migrating-from-rackspace.md](../../documentation/docs/guide/migrating-from-rackspace.md) |

## How to make any change safely

1. **Restate the goal** in one sentence and say which file and option you
   will change. Look the option up in `terranix/sql-server.nix`; its
   `description` says what it does and whether changing it replaces things.
2. **Warn before risky changes.** These replace (delete and recreate) the
   VM or everything: `name`, `location`, `vm.adminUsername`, `vm.image`,
   `resourceGroupName`, a disk's `lun`, shrinking any disk. `protectData`
   (on by default) makes OpenTofu refuse to delete the VM or data disks;
   never turn it off to "get a plan through" without the person's explicit
   go-ahead and a verified database backup.
3. **Edit, then `fmt` and `check`.** Both must pass.
4. **Run `plan` and read it with them.** Count the symbols:
   `+` create, `~` change in place, `-/+` replace, `-` destroy. Any `-` or
   `-/+` on `azurerm_windows_virtual_machine`, `azurerm_managed_disk` or
   `azurerm_resource_group` means data loss: stop and explain.
5. **`apply` only when they agree.** It shows the plan again and waits for
   `yes`.
6. **Commit on a branch and open a PR.** Never push to `main`.

## Hard rules

- Public repo: never write a secret, bucket name, IP address, subscription
  or tenant id into any file, commit message, PR or log. Private values go
  in 1Password, referenced from `.env.schema` as `op(op://azure-infra/<item>/<field>)`.
- Never print secret values. Check presence with `printenv NAME >/dev/null`
  or `nix run .#op -- item get <item> --vault azure-infra --fields label=<f>`
  only when the person asks to see a value.
- Never delete or overwrite state, run `tofu state rm`, `tofu import`,
  `tofu force-unlock` or `destroy` without the person's explicit approval
  for that exact command. Explain what it does first.
- Never change the `tofu-state-passphrase` item: the state is encrypted
  with it and becomes unreadable.
- Load the `nix-style` and `terranix` skills (if installed) before
  editing `.nix` files; the org style is enforced by `fmt`/`check`.
