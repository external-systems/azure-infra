# azure-infra

One server on Microsoft Azure, described as code: a Windows Server 2019
virtual machine running **SQL Server 2019 Web edition**, with its network,
firewall and disks. It replaces the old server at Rackspace.

**New here, no Azure account, not technical?** Start with
[Getting started](getting-started.md): everything in the browser.

<iframe src="slides/index.html" title="Slide deck"
  style="width: 100%; aspect-ratio: 16 / 9; border: 0;"
  allowfullscreen></iframe>

## How it works

```
terranix/settings.nix --(Nix, terranix)--> config.tf.json --(OpenTofu)--> Azure
       you edit                               generated                real server
                                                  |
                        state: what OpenTofu built last time
                        encrypted, in a private Azure storage account
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
| Region | `southcentralus` (San Antonio, Texas) |
| VM | `Standard_D4s_v5` (4 vCPU, 16 GiB), Windows Server 2019 + SQL Server 2019 Web, SQL license paid per hour |
| Disks | C: 127 GiB, F: data 256 GiB, G: log 128 GiB (Premium SSD); tempdb on the local D: |
| Network | Private network `10.50.0.0/16`, static public IP |
| Firewall | Closed. RDP and SQL open only to the IPs you list in 1Password |
| Logins | Windows `azureadmin` and SQL `sqladmin`, passwords generated into 1Password |
| Safety | Encrypted state; the VM and data disks refuse to be deleted (`protectData`) |

## Day to day

Changes go through pull requests; GitHub Actions does the rest:

| Where | What happens |
|---|---|
| Pull request to `main` | `check` and `plan`; the plan is posted on the pull request |
| Merge to `main` | `plan` again, then `apply` after a reviewer approves `azure-production` |
| Actions > Infrastructure > Run workflow | Plan and apply `main` without a code change |
| Push to `main` | The docs are published to GitHub Pages |

Nobody needs local tools. **Not technical?** Start with
[For the operator](operator.md). Admins: [First-time setup](guide/first-time-setup.md)
and [GitHub setup](guide/github-setup.md). Changing something:
[Making changes](guide/making-changes.md). Working with an AI agent:
[AI assistance](ai-skill.md).
