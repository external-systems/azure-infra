# azure-infra

One SQL Server on Azure, built from code

Note: Press `S` for the speaker view, `F` for fullscreen. Audience: people who will change this server with an AI agent and have never used Azure.

---

## Why

- The database server lives at Rackspace today
- Moving to Azure: Windows Server 2019 + SQL Server 2019 **Web**
- No clicking in the portal: the server is described in files, reviewed in PRs

---

## What gets built

- One VM (`Standard_D4s_v5`: 4 vCPU, 16 GiB)
- Disks: C: Windows, F: data, G: logs, D: tempdb (temporary)
- A private network, a static public IP, a closed firewall
- Two logins, passwords generated into 1Password

--

## Azure in one slide

| Azure word | Means |
|---|---|
| Subscription | the bill |
| Resource group | a folder of resources |
| VNet / subnet | our private network |
| NSG | the firewall |
| SQL IaaS extension | license, disks, patching for SQL |

---

## How a change happens

```
settings.nix  ->  terranix  ->  config.tf.json  ->  OpenTofu  ->  Azure
```

1. Edit a Nix file
2. `plan`: see the difference, nothing changes
3. `apply`: type `yes`, Azure changes
4. Open a PR

---

## Reading a plan

| Symbol | Meaning |
|---|---|
| `+` | create |
| `~` | change in place |
| `-/+` | **replace** (delete, recreate) |
| `-` | **destroy** |

Note: Any minus on the VM, a disk or the resource group means data loss. The repo refuses those by default (protectData).

---

## Secrets

- Public repo: no passwords, keys, bucket names or IPs in it
- `.env.schema` holds only `op://` references
- Varlock + 1Password plugin load them for each tofu run
- Desktop app with biometric unlock, or a service account in CI

--

## The state

- OpenTofu's memory of what it built
- Contains the server passwords, so it is **encrypted**
- Stored in a private Hetzner bucket, locked during applies
- Never delete it, never change its passphrase

---

## Working with the AI agent

- The `azure-infra` skill ships in the repo
- Ask in plain words: "open RDP for my IP"
- The agent edits, runs `check` and `plan`, explains
- You decide on `apply`

---

## Common changes

- Firewall IPs: edit `sql-server-settings` in 1Password, `apply`
- Bigger VM: `vm.size`, `apply` (reboots)
- Bigger disk: `disks.data.sizeGb`, `apply`, extend F: in Windows
- Patch window: `sql.autoPatching`

---

## Next steps

1. First-time setup (1Password, Azure, Hetzner)
2. First `apply`
3. Rehearse the database move
4. Cutover, then backups

---

# Questions?

Docs: `docs-build`, then open `result-docs/index.html`
