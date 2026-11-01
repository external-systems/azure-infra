# Making changes

Every change to the server goes through a pull request. GitHub Actions
plans it, a person reads the plan and says yes, and GitHub applies it. No
one needs any tools on their computer. Recipes for common requests are at
the end.

## The loop

### 1. Understand the request

Restate it in one plain sentence and name the setting you will change.
Every option is in `terranix/sql-server.nix` with a `description` saying
what it does and whether changing it rebuilds anything. Most values are set
in `terranix/settings.nix`.

### 2. Branch and edit

Create a branch from the latest `main` (e.g. `change/bigger-server`),
make the smallest edit that does it, commit with a message that says why.
Never edit `.github/`, never put a password, key, bucket name or IP address
in a file.

Locally, with the devenv shell, also run `fmt` and `check`. In the browser
there is nothing to run: CI's `check` job does the same.

### 3. Open the pull request

Push the branch and open a pull request to `main`. Write the description
for the operator, in plain words: what changes, what it costs, whether the
database goes offline. No IPs or secrets: the repo and its pull requests
are public.

### 4. Wait for the plan

The **Infrastructure** workflow runs two jobs on the pull request:

- `check`: formatting, lint, docs build, offline validation. Red means the
  edit itself is wrong; read the log, fix, push again.
- `plan`: asks Azure what would change and posts the result as a comment on
  the pull request ("OpenTofu plan"), updated on every push.

Both must be green before GitHub allows a merge.

### 5. Read the plan and explain it

The comment's bold line is the summary: `Plan: X to add, Y to change, Z to
destroy.` The full plan is under "Full plan". Each resource has a symbol:

| Symbol | Meaning | Risk |
|---|---|---|
| `+` | create | Low; costs money from now on |
| `~` | change in place | Usually low; some (VM size) restart the VM |
| `-/+` | destroy, then create (replace) | **High** on the VM, disks or resource group |
| `-` | destroy | **High** |
| `<= read` | read data (1Password vault lookup) | None |

Lines marked `# forces replacement` say which setting caused a `-/+`.
`(known after apply)` only means Azure picks the value. `(sensitive value)`
hides passwords and IP lists, on purpose: the page is public.

`Instance cannot be destroyed` (the plan fails) means the change would
delete the VM or a data disk, and the repo refuses. Undo the edit, or treat
it as a migration with Andrew (see "Anything that replaces the server").

"No changes" after an edit means the edit did nothing: find out why before
merging.

Then ask the operator plainly whether to go ahead.

### 6. Merge

Only after a clear yes. Merge the pull request into `main` (squash).

### 7. Approve the apply

The merge starts the workflow on `main`: `check`, `plan` again, then
`apply`, which waits in the `azure-production` environment. A required
reviewer opens the run (Actions > Infrastructure > the newest run on
`main`) and clicks **Review deployments** > `azure-production` > **Approve and
deploy**. The agent cannot do this.

If the plan on `main` differs from the one on the pull request (something
else merged in between), explain the difference before approving. If no
change is needed, `apply` is skipped.

### 8. Report

`apply` applies exactly the approved plan. Read the end of its log
(`Apply complete! Resources: ...`) and tell the operator it is done. A
failure: see [troubleshooting](troubleshooting.md). If the plan went stale
(Azure changed in between), run the workflow again.

### Without a code change

Actions > Infrastructure > **Run workflow** (branch `main`) runs plan and
apply (with the approval) for the current `main`. Use it after editing
values that live in 1Password (firewall IPs), or to undo drift.

### Locally (Andrew)

The same steps work from a laptop in the devenv shell: `plan`, `apply`
(asks for `yes`), `tofu output -raw public_ip`. Prefer the pull request
path so there is a record.

## Recipes

### Let someone connect with Remote Desktop (or remove access)

Firewall IPs are private, so they live in 1Password, not in the repo.

1. Someone with access to the `azure-infra` vault edits item
   `sql-server-settings`, field `rdp_source_cidrs`: a comma-separated list
   such as `198.51.100.7/32, 203.0.113.9/32`. To find a home connection's
   address, open <https://ifconfig.me> on that network. Empty field: nobody
   can connect from the internet.
2. Actions > Infrastructure > Run workflow on `main`.
3. The plan should show only `allow_rdp` being added, changed or removed.
   Approve the deployment.
4. Connect: the server's address is in the 1Password item `<name> Windows
   admin` (its website field, `rdp://<address>`). Use Remote Desktop
   (Windows: "Remote Desktop Connection"; Mac: "Windows App") with user
   `azureadmin` and that item's password.

### Let the web servers reach SQL Server

1. In `terranix/settings.nix`: `sqlServer.sql.connectivity = "PUBLIC";`
   (pull request as above).
2. In 1Password `sql-server-settings`, `sql_source_cidrs`: the web servers'
   public IPs, comma-separated. They never go in the repo.
3. Plan: `allow_sql` created and `azurerm_mssql_virtual_machine.sql`
   changed in place. No downtime.
4. Connection string for the web apps: host and port from the 1Password
   item `<name> SQL login`, with `Encrypt=True`.

Once the web servers move into Azure (same virtual network), switch back
to `PRIVATE` and empty the field.

### Make the server bigger or smaller

1. `terranix/settings.nix`: `sqlServer.vm.size = "Standard_D8s_v5";`
   (8 vCPU, 32 GiB). Common steps: `D2s_v5` (2/8), `D4s_v5` (4/16, the
   default), `D8s_v5` (8/32), `D16s_v5` (16/64). Web edition uses at most
   16 cores and 64 GB of buffer pool, so bigger than `D16s_v5` wastes money.
   Each step up roughly doubles the compute cost.
2. Plan: `~ size` on the VM, in place. Applying **restarts** the server:
   the database is offline for a few minutes. Pick a quiet time.
3. If apply fails with `SkuNotAvailable` or a quota error, see
   [troubleshooting](troubleshooting.md).

### Grow a data disk

1. `terranix/settings.nix`:
   ```nix
   sqlServer.disks = {
     data = {
       lun = 0;
       sizeGb = 512;
       caching = "ReadOnly";
       path = "F:\\data";
     };
     log = {
       lun = 1;
       sizeGb = 128;
       caching = "None";
       path = "G:\\log";
     };
   };
   ```
   Repeat both disks: setting `disks` replaces the whole default.
2. Plan: `~ disk_size_gb` in place, no downtime. Disks only grow; shrinking
   forces replacement and loses data (`prevent_destroy` blocks it).
3. After apply, someone with Remote Desktop access extends the volume in
   Windows: Server Manager > File and Storage Services > Storage Pools (the
   SQL extension made one), extend the virtual disk and the F: volume.

### Change the patch window

`terranix/settings.nix`:

```nix
sqlServer.sql.autoPatching = {
  dayOfWeek = "Saturday";
  startHour = 3;
};
```

Hour in the VM's time zone. Plan shows the `auto_patching` block changing.
No downtime now; the server may restart inside the new window.

### Add a tag, change the time zone

`sqlServer.tags` and `sqlServer.vm.timezone` (Windows IDs like
`"Central Standard Time"`). In place.

### Anything that replaces the server

`name`, `location`, `resourceGroupName`, `vm.adminUsername`, `vm.image`.
Treat these as a migration, not an edit: a new server next to the old one,
move the data, switch over. Explain this to the operator and involve Andrew
before touching them.
