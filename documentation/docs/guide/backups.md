# Backups and recovery

In plain words: what is saved, where, for how long, and what to do when
something goes wrong. You do not have to do anything for backups to
happen: they run by themselves.

## The short version

- **Your databases are backed up automatically**, all the time, and kept
  for **30 days**.
- You can get a database back **as it was at any minute** in those 30 days.
- The backups are stored **twice**: in Texas, and again in a second Azure
  region far away (North Central US, Illinois). A disaster in one place
  does not lose them.
- The server's disks **cannot be deleted by accident**: the project refuses
  any change that would delete them.
- All passwords are in **1Password**, so nothing needed for a recovery is
  only in someone's head.

## What is backed up

| What | How | Kept | Where |
|---|---|---|---|
| Every database (your data) | SQL Server Automated Backup: a full copy regularly, plus a small "what changed" file every few minutes | 30 days (`sql.backup.retentionDays`) | Storage account `sqlbk...` in the server's resource group, copied to a second region (GRS) |
| SQL Server's own settings (logins, jobs) | Same, "system databases" | 30 days | Same place |
| The robot's notes (OpenTofu state) | Every change keeps the previous version | 30 days | The state storage account (`rg-azure-infra-state`) |
| Passwords and settings | 1Password keeps every old version of an item | Forever | 1Password |
| The recipe for the whole server | This repository on GitHub | Forever | GitHub |

What is **not** backed up: files someone saves by hand on the server's C:
drive or desktop (outside SQL Server). Keep important files in a database
or somewhere else.

## How it works

```
SQL Server on the server
   | every few minutes: changes since last time (log backup)
   | regularly: a full copy of each database
   v
Backup storage account (Texas) --automatic copy--> second region (Illinois)
   | older than 30 days: deleted automatically
```

The SQL Server "IaaS extension" (a helper Azure installs on the server)
runs the schedule. Nobody has to log in for it to work.

## Checking that backups work (monthly, 5 minutes)

Ask Claude: *"Are the database backups working?"* Claude can walk you
through it, or ask Andrew. In the Azure portal:

1. Search **SQL virtual machines**, open `sql-web-01`.
2. Click **Backups** on the left. It should say Automated backup
   **Enabled**, retention **30 days**.
3. Search **Storage accounts**, open the one starting with `sqlbk`, click
   **Containers**. There is a container with recent files (dates from
   today or yesterday).

If the dates are old or the page says Disabled: tell Andrew.

A backup you have never restored is a hope, not a backup. Once every few
months, Andrew (or whoever looks after the databases) restores one
database **as a copy** under a new name, checks it opens, and deletes the
copy (see "Someone deleted or broke data" below).

## When something goes wrong

### Someone deleted or broke data (the most common case)

Example: "Yesterday at 3pm someone deleted all the orders."

1. Write down **when** it happened, as exactly as you can.
2. **Do not** try to fix it in the live database yourself.
3. Tell Andrew (or your database person). They restore the database **as a
   copy, next to the original**, at a minute before the mistake, then copy
   the lost rows back. The live database keeps running the whole time.

For the technical person: Remote Desktop to the server, open SQL Server
Management Studio, right-click **Databases** > **Restore Database**,
source **Device** > **URL**, add the `sqlbk...` storage account (its
access key is in the portal under Storage account > Access keys), pick the
backup files, choose a **new database name**, and on **Timeline** pick
the point in time.

No Azure or GitHub change is needed for this. Nothing here goes through
the robot.

### The whole server is broken (won't start, Windows is damaged)

1. Tell Andrew. Try first: Azure portal > the VM > **Restart**, then
   **Redeploy + reapply** (moves it to fresh hardware, keeps the disks).
2. If Windows itself is lost: the data disks and the backups are still
   there. Andrew builds a new server with this repository (a planned change,
   reviewed like any other) and restores the databases from the backups.
   Expect hours, not minutes.

### A whole Azure region goes down (very rare)

The backups have a second copy in North Central US. Azure decides when a
region is really lost; then Andrew can switch the backup storage to the
second region and build a server there from this repository. Plan for a
day of work. The `location` setting is the one that changes.

### Something went wrong with the robot's notes (state)

Symptoms: plans suddenly want to create things that already exist, or
`tofu init` cannot read the state. **Do not** delete anything in Azure.
Ask Andrew: the state storage keeps 30 days of old versions, and the
[troubleshooting](troubleshooting.md) page covers the details.

## Changing the backup settings

All in `terranix/settings.nix`, in place, no downtime. Ask Claude, for
example *"keep backups for 60 days"*.

| Setting | Default | Means |
|---|---|---|
| `sql.backup.enable` | `true` | Turn automatic backups on or off. Leave it on. |
| `sql.backup.retentionDays` | `30` | Days to keep (1 to 90). More days cost a little more ([costs](costs.md)). |
| `sql.backup.replication` | `GRS` | `GRS`: a copy in a second region. `LRS`: one region only, cheaper. |

## Moving from Rackspace

The first copy of the databases comes from Rackspace backups (`.bak`
files), restored on the new server: see
[Migrating from Rackspace](migrating-from-rackspace.md). Automated backups
start protecting each database as soon as it exists on the new server.
