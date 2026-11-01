# azure-infra

One server on Microsoft Azure, described as code: a Windows Server 2019
virtual machine running **SQL Server 2019 Web edition**, with its network,
firewall and disks. It replaces the old server at Rackspace.

<iframe src="slides/index.html" title="Slide deck"
  style="width: 100%; aspect-ratio: 16 / 9; border: 0;"
  allowfullscreen></iframe>

## How it works

```
terranix/settings.nix --(Nix, terranix)--> config.tf.json --(OpenTofu)--> Azure
       you edit                               generated                real server
                                                  |
                        state: what OpenTofu built last time
                        encrypted, in a private Hetzner Object Storage bucket
```

- **terranix** turns the Nix files in `terranix/` into OpenTofu's JSON.
- **OpenTofu** compares that with Azure: `plan` shows the difference,
  `apply` makes Azure match after you type `yes`.
- **1Password** holds every credential and private value. **Varlock** reads
  them through its 1Password plugin (`.env.schema`) each time OpenTofu runs.
  The repo is public and contains only `op://` references.

## What gets built

| Piece | Default |
|---|---|
| Region | `eastus2` |
| VM | `Standard_D4s_v5` (4 vCPU, 16 GiB), Windows Server 2019 + SQL Server 2019 Web, SQL license paid per hour |
| Disks | C: 127 GiB, F: data 256 GiB, G: log 128 GiB (Premium SSD); tempdb on the local D: |
| Network | Private network `10.50.0.0/16`, static public IP |
| Firewall | Closed. RDP and SQL open only to the IPs you list in 1Password |
| Logins | Windows `azureadmin` and SQL `sqladmin`, passwords generated into 1Password |
| Safety | Encrypted state; the VM and data disks refuse to be deleted (`protectData`) |

## Day to day

Inside the devenv shell, from the repo root:

```sh
plan          # what would change (safe)
apply         # change Azure, asks for yes
tofu output   # public IP, private IP
env-check     # are the 1Password values reachable? (redacted)
fmt && check  # before every commit
```

New here? Read [Azure concepts](guide/azure-concepts.md), then
[First-time setup](guide/first-time-setup.md). To change something, see
[Making changes](guide/making-changes.md). Working with an AI agent? See
[AI assistance](ai-skill.md).
