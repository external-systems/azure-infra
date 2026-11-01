# Migrating the databases from Rackspace

The goal of the project: move the databases from the old Windows Server
2019 / SQL Server Web machine at Rackspace onto the server this repo
builds, with a short, planned cutover. OpenTofu builds the server; moving
data is done by hand with SQL Server tools. Work through this with the
person step by step and keep notes in the PR or an issue (no IPs or
passwords).

## 0. Inventory the old server

On the Rackspace server, in SSMS:

```sql
SELECT @@VERSION;                                   -- edition and build
SELECT name, compatibility_level, recovery_model_desc,
       (SELECT SUM(size) * 8 / 1024 FROM sys.master_files f
        WHERE f.database_id = d.database_id) AS size_mb
FROM sys.databases d WHERE database_id > 4;
```

Also list: SQL logins (`sys.server_principals`), SQL Agent jobs, linked
servers, scheduled tasks, anything on disk the apps read (file shares,
certificates), and every app or web server with a connection string.

Size the Azure disks from `size_mb` with room to grow ([making-changes](making-changes.md),
"Grow a data disk") before `apply`.

## 1. Build and reach the new server

First-time setup, then `apply`. Open RDP for the person's IP and, during
the migration, SQL from the Rackspace web servers' IPs
([making-changes](making-changes.md)).

## 2. Rehearse with a full backup

On Rackspace:

```sql
BACKUP DATABASE [AppDb] TO DISK = 'D:\migrate\AppDb.bak'
  WITH COMPRESSION, CHECKSUM, COPY_ONLY;
```

`COPY_ONLY` keeps the old server's own backup chain intact.

Copy the `.bak` files to the new server's `F:\backup\`: for small files,
RDP drive redirection or clipboard; for large ones, `azcopy` through a
temporary Azure storage container (create it in the portal, delete it
after), or any file transfer the person already uses.

On Azure (RDP, SSMS):

```sql
RESTORE FILELISTONLY FROM DISK = 'F:\backup\AppDb.bak';   -- logical names
RESTORE DATABASE [AppDb] FROM DISK = 'F:\backup\AppDb.bak'
  WITH MOVE 'AppDb' TO 'F:\data\AppDb.mdf',
       MOVE 'AppDb_log' TO 'G:\log\AppDb_log.ldf',
       CHECKSUM, STATS = 10;
```

Then:

- **Logins**: recreate SQL logins with the same SIDs, so database users
  stay attached. Microsoft's `sp_help_revlogin` script generates the
  `CREATE LOGIN` statements on the old server. Fix any orphan with
  `ALTER USER [u] WITH LOGIN = [u];` (`EXEC sp_change_users_login 'Report';`
  lists them).
- **Agent jobs**: script them in SSMS (SQL Server Agent > Jobs > Script Job
  as > CREATE) and run on the new server.
- **Test**: point a staging copy of the web app at the new server and click
  through it.

## 3. Cutover (planned downtime)

1. Announce a window. Rough length: time to back up, copy and restore the
   biggest database during the rehearsal, plus 30 minutes.
2. Stop the web apps (or put them in maintenance mode) so nothing writes.
3. Final backup on Rackspace (full, or a differential on top of a full
   restored earlier `WITH NORECOVERY` to shorten the window), copy, restore
   `WITH RECOVERY` on Azure.
4. Change connection strings (or the DNS name they use) to the Azure server.
5. Start the apps, test, watch errors.
6. Keep the old server running read-only for a few days as a fallback, then
   cancel it at Rackspace.

## 4. After the move

- Set up backups ([operations](operations.md), "Backups"). This is the first priority.
- Remove temporary firewall entries (`sql_source_cidrs`) once the web
  servers are also in Azure, and switch `sql.connectivity` back to
  `PRIVATE`.
- Check the Web edition licensing still fits the use ([azure-concepts](azure-concepts.md)).
