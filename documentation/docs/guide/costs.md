# Costs

An estimate of what the server costs each month, worked out from the
settings in `terranix/settings.nix` and the defaults in
`terranix/sql-server.nix`. Azure bills per hour; a month is 730 hours.

!!! note "Keep this page in step with the configuration"
    Any change to the region, VM size, disks, image or public IP updates
    the table below in the same pull request. The pull request description
    says how the monthly total changes.

Last checked: **2026-11-01**. List prices, pay-as-you-go, USD.

## Current configuration

| Setting | Value |
|---|---|
| Region | `southcentralus` (South Central US, San Antonio, Texas) |
| VM size | `Standard_D4s_v5` (4 vCPU, 16 GiB) |
| Image | SQL Server 2019 Web on Windows Server 2019, pay-as-you-go licensing |
| Disks | OS 127 GB, data 256 GB, log 128 GB, all Premium SSD (LRS) |
| Public IP | 1 static, Standard |
| Backups | SQL Automated Backup, 30 days, geo-redundant storage (GRS) |
| State | OpenTofu state in a small GRS storage account |

## Monthly estimate

![About $385 a month: server and Windows $275, SQL license $25, disks $78, backups and address $9](../diagrams/cost.svg)

| Item | How it is billed | Approx. / month |
|---|---|---|
| VM compute + Windows license (`Standard_D4s_v5`, ~$0.376/h) | per hour while running | ~$275 |
| SQL Server Web license (4 cores) | per hour while running | ~$25 |
| OS disk, 127 GB Premium SSD (P10) | per month, always | ~$20 |
| Log disk, 128 GB Premium SSD (P10) | per month, always | ~$20 |
| Data disk, 256 GB Premium SSD (P15) | per month, always | ~$38 |
| Static public IP (Standard) | per hour, always | ~$4 |
| Backup storage (GRS, about $0.05 per GB) | per GB stored | ~$5 for 100 GB of backups |
| State storage (a few MB) | per GB stored | under $1 |
| Outbound traffic | first 100 GB/month free, then ~$0.09/GB | $0 to a few dollars |
| Virtual network, firewall (NSG), boot diagnostics | free or negligible | ~$0 |
| **Total** | | **~$385** |

How sure these numbers are:

- VM and disk prices are East US list prices from public price trackers.
  South Central US is usually the same or slightly higher.
- The SQL Server Web license line is the least certain.
- Before relying on the total, check it in the
  [Azure pricing calculator](https://azure.microsoft.com/pricing/calculator/)
  (region South Central US). The real bill is in the portal: Cost
  Management, filtered by resource group `rg-<name>` or tag
  `managed-by = azure-infra`.

## What changes the cost

| Change | Effect on the monthly total |
|---|---|
| VM size one step down (`Standard_D2s_v5`, 2 vCPU, 8 GiB) | VM + licenses roughly halve: total ~$240 |
| VM size one step up (`Standard_D8s_v5`, 8 vCPU, 32 GiB) | VM + licenses roughly double: total ~$680 |
| Data disk 256 GB to 512 GB (P15 to P20) | about +$35 |
| Backup retention 30 to 60 days | backup storage roughly doubles (a few dollars) |
| Backup replication GRS to LRS | backup storage roughly halves, but no copy in a second region |
| Region | small differences; Central US is similar |
| SQL connectivity `PUBLIC` vs `PRIVATE` | no cost change |
| Firewall IPs (1Password) | no cost change |

## Saving money

- **Savings plan or reservation** (1 or 3 years, bought in the portal,
  nothing changes in this repo): cuts the compute part by roughly 30-50%.
  The Windows and SQL licenses are not discounted.
- **Azure Hybrid Benefit**: if you already own Windows Server or SQL
  Server licenses with Software Assurance, the license lines can drop.
  Ask Andrew; it needs a repo change.
- **Deallocate** the VM (Azure portal > the VM > Stop) stops the compute and
  license charges; disks and the public IP are still billed. Shutting down
  from inside Windows does **not** stop billing.
