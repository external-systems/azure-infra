# Azure concepts used by this repo

Plain-language explanations of every Azure piece `terranix/sql-server.nix`
creates, in the order they depend on each other. Use these words with the
person; avoid unexplained jargon.

## Account structure

| Term | Plain meaning |
|---|---|
| **Tenant** | The organization's Azure login directory (Microsoft Entra ID). People and robot accounts live here. |
| **Subscription** | The billing account. Everything here is billed to one subscription. |
| **Service principal** | A robot user. OpenTofu logs in as one (`azure-service-principal` in 1Password) with the *Contributor* role on the subscription: it may create and delete resources but not manage permissions. |
| **Resource group** | A folder for resources (`rg-sql-web-01`). Deleting it deletes everything inside. |
| **Region / location** | The data center area (`southcentralus`, San Antonio, Texas). Pick one close to the users and the web servers. Moving region means rebuilding. |

## Network

| Resource | Name pattern | Plain meaning |
|---|---|---|
| `azurerm_virtual_network` | `vnet-<name>` | A private network (`10.50.0.0/16`) only our resources are on. |
| `azurerm_subnet` | `snet-<name>` | A slice of that network (`10.50.1.0/24`) the VM sits in. |
| `azurerm_network_security_group` | `nsg-<name>` | The firewall. Azure blocks all inbound internet traffic unless a rule allows it. |
| `azurerm_network_security_rule` | `allow-rdp`, `allow-sql` | The only two holes: RDP (3389) and SQL (1433), each limited to the CIDRs stored in 1Password (`sql-server-settings`). With an empty field the rule is not created at all. |
| `azurerm_public_ip` | `pip-<name>` | A fixed (static) public IPv4 address. It stays the same across reboots and resizes. |
| `azurerm_network_interface` | `nic-<name>` | The VM's network card: private IP in the subnet plus the public IP. |

A CIDR such as `198.51.100.7/32` means "exactly this one address";
`198.51.100.0/24` means the 256 addresses `198.51.100.0`-`.255`.

## The server

| Resource | Plain meaning |
|---|---|
| `azurerm_windows_virtual_machine` (`vm-<name>`) | The Windows server. `size` sets CPU and RAM (`Standard_D4s_v5` = 4 vCPU, 16 GiB). |
| Marketplace image `MicrosoftSQLServer / sql2019-ws2019 / web` | Microsoft's ready-made Windows Server 2019 with SQL Server 2019 Web already installed. |
| OS disk (C:) | Windows itself, 127 GiB Premium SSD. |
| Temporary disk (D:) | Fast local disk that is **wiped** on resize, redeploy or host maintenance. Only tempdb lives there, which SQL Server recreates on start. Never store anything else on D:. |
| `azurerm_managed_disk` `data` (F:) and `log` (G:) | Separate Premium SSDs for database files and transaction logs. They survive VM rebuilds and have `prevent_destroy`. |
| `azurerm_virtual_machine_data_disk_attachment` | Plugs a data disk into the VM at a LUN (slot number). |
| System-assigned identity | Lets the VM itself authenticate to Azure later (for example, backups to storage) without a password. |
| Boot diagnostics | Screenshot and serial log of the VM in the portal, useful when it will not boot or RDP fails. |

## SQL Server specifics

| Item | Plain meaning |
|---|---|
| `azurerm_mssql_virtual_machine` | Registers the VM with the **SQL IaaS Agent extension**. It sets the license model, creates the SQL login, formats F: and G: and points SQL Server at them, opens the listener scope, and runs the patch window. |
| `sql_license_type = "PAYG"` | Pay-as-you-go: the SQL license is included in the per-hour VM price. Nothing to buy separately. |
| `sql.connectivity` | `LOCAL` = only from the VM; `PRIVATE` = from the virtual network; `PUBLIC` = from the internet, still filtered by the `allow-sql` NSG rule. |
| SQL login `sqladmin` | A SQL authentication sysadmin login; its password is generated in 1Password (`<name> SQL login`). |
| Windows admin `azureadmin` | The Windows login for RDP; password in 1Password (`<name> Windows admin`). |

### Web edition limits and licensing

- Uses at most the lesser of 4 sockets or 16 cores, and 64 GB of memory for
  the buffer pool. A VM bigger than that wastes money.
- Licensing: Web edition may only serve public, internet-accessible web
  pages, websites, web applications and web services. It is not allowed
  for internal line-of-business apps, reporting for staff, and so on. If
  the use changes, the edition has to change (Standard), which means a new
  image and a migration.
- Support dates: Windows Server 2019 extended support ends 9 January 2029,
  SQL Server 2019 on 8 January 2030. Plan the next upgrade before then.

## 1Password items

| Item (vault `azure-infra`) | Fields | Made by |
|---|---|---|
| `azure-service-principal` | `subscription_id`, `tenant_id`, `client_id`, `client_secret` | You, once |
| `tofu-state-passphrase` | `password` | You, once (generated) |
| `sql-server-settings` | `state_storage_account`, `rdp_source_cidrs`, `sql_source_cidrs` (comma-separated CIDRs, may be empty) | You, once; edit to change firewall |
| `<name> Windows admin` | username, password, URL | OpenTofu (generated by 1Password) |
| `<name> SQL login` | username, password, host, port | OpenTofu (generated by 1Password) |

## Why the state is encrypted

OpenTofu remembers what it built in a **state** file. Azure's API takes the
admin and SQL passwords as plain arguments, so they end up in that file.
`terranix/state.nix` turns on OpenTofu state encryption (AES-GCM, key
derived from `tofu-state-passphrase`) and `enforced = true` makes OpenTofu
refuse to ever write it unencrypted. The encrypted file lives in a private
Azure storage account (resource group `rg-azure-infra-state`, made once by
`scripts/azure-bootstrap.sh`, not by OpenTofu). A blob lease locks it
during a run, so two runs cannot apply at the same time, and blob
versioning keeps old copies for 30 days.
