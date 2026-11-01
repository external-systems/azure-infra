# Making changes

Every change follows the same loop: edit, `fmt`, `check`, `plan`, read the
plan together, `apply`, open a PR. Recipes for the common requests follow.

## Reading a plan

`plan` ends with `Plan: X to add, Y to change, Z to destroy.` Each resource
has a symbol:

| Symbol | Meaning | Risk |
|---|---|---|
| `+` | create | Low; costs money from now on |
| `~` | change in place | Usually low; some (VM size) reboot the VM |
| `-/+` | destroy, then create (replace) | **High** on the VM, disks or resource group |
| `-` | destroy | **High** |
| `<= read` | read data (1Password vault lookup) | None |

Lines marked `# forces replacement` say which argument caused a `-/+`.
`(known after apply)` only means Azure decides the value; it is not a
problem. `(sensitive value)` hides passwords; that is expected.

If the plan includes `prevent_destroy`-related errors (`Instance cannot be
destroyed`), the change would delete the VM or a data disk. Stop. Find which
setting forced it, and either undo it or plan a migration with a verified
backup (see [operations](operations.md)).

A plan with **no changes** after an edit usually means the edit was in a
file Nix does not see: `git add` it.

## Recipes

### Let someone RDP in (or remove access)

Firewall IPs are private, so they live in 1Password, not in the repo.

1. Edit item `sql-server-settings`, field `rdp_source_cidrs`: a
   comma-separated list, e.g. `198.51.100.7/32, 203.0.113.9/32`. Their IP:
   `curl -4 ifconfig.me` on their machine. Empty field: no RDP at all.
2. `plan`: expect `allow_rdp` to be created, changed or destroyed. Nothing
   else.
3. `apply`.
4. Connect: `tofu output public_ip`, then Remote Desktop (Windows `mstsc`,
   macOS "Windows App") to that IP as `azureadmin`; password in 1Password
   item `<name> Windows admin`.

No repo change, so no PR is needed.

### Let the web servers reach SQL Server

1. In `terranix/settings.nix`: `sqlServer.sql.connectivity = "PUBLIC";`
2. In 1Password `sql-server-settings`, `sql_source_cidrs`: the web servers'
   public IPs (comma-separated). Ask the person for them; they never go in
   the repo.
3. `fmt`, `check`, `plan`: expect `allow_sql` created and
   `azurerm_mssql_virtual_machine.sql` changed in place.
4. `apply`. Connection string: host `tofu output public_ip`, port 1433,
   login from 1Password `<name> SQL login`. Use `Encrypt=True`.

Once the web servers move into Azure (same virtual network), switch back
to `PRIVATE` and empty the field.

### Make the VM bigger or smaller

1. `terranix/settings.nix`: `sqlServer.vm.size = "Standard_D8s_v5";`
2. Check the size exists in the region:
   `az vm list-sizes --location eastus2 -o table`. Web edition uses at most
   16 cores and 64 GB buffer pool, so going beyond about `D16s_v5` wastes
   money.
3. `plan`: `~ size` on the VM, in place. Applying **reboots** the server
   (a few minutes of downtime). Pick a quiet time.

### Grow a data disk

1. `terranix/settings.nix`:
   ```nix
   sqlServer.disks = {
     data = {lun = 0; sizeGb = 512; caching = "ReadOnly"; path = "F:\\data";};
     log = {lun = 1; sizeGb = 128; caching = "None"; path = "G:\\log";};
   };
   ```
   Repeat both disks: setting `disks` replaces the whole default.
2. `plan`: `~ disk_size_gb` in place. Disks only grow; shrinking forces
   replacement and loses data (`prevent_destroy` blocks it).
3. After `apply`, extend the volume in Windows: RDP in, Disk Management
   (or Server Manager > Storage Pools, since the SQL extension created a
   storage pool), extend F:.

### Change the patch window

`terranix/settings.nix`:
`sqlServer.sql.autoPatching = {dayOfWeek = "Saturday"; startHour = 3;};`
(hour in the VM's time zone). Plan shows the `auto_patching` block changing.

### Add a tag, change the time zone

`sqlServer.tags` and `sqlServer.vm.timezone` (Windows IDs like
`"Central Standard Time"`, list them with `tzutil /l` on the VM). In place.

### Anything that replaces the server

`name`, `location`, `resourceGroupName`, `vm.adminUsername`, `vm.image`.
Treat these as a migration, not an edit: new server next to the old one,
move data, cut over. Explain this to the person before touching them.

## After the change

`git switch -c <branch>`, commit the edit with a message that says why,
push, open a PR to `main`. Paste the plan summary line into the PR (not the
full plan: it can contain IPs).
