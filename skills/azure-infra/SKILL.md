---
name: azure-infra
description: "Help the operator of the external-systems/azure-infra repo understand and change their Azure SQL server through pull requests: one Windows Server 2019 VM with SQL Server 2019 Web edition, built with terranix and OpenTofu, planned and applied by GitHub Actions, secrets in 1Password. The operator may be completely non-technical and works only in a browser. Load for any question or change about this repo, the server, its firewall, size, disks, passwords, costs, a plan on a pull request, a failed run, or the move from Rackspace."
---

# azure-infra

This repo describes one rented computer at Microsoft Azure: a Windows
server running the SQL Server database (Web edition), plus its network,
firewall and disks. Nobody changes it by clicking in Azure. A change is a
small edit to a file here; GitHub's robot (GitHub Actions) shows what the
edit would do, a person says yes, and the robot makes the change.

## Who you are talking to

Assume the person (the **operator**) knows nothing about Azure, Terraform,
Linux, Git or code, and is talking to you in a web browser. They have no
tools installed and do not need any. So:

- Use plain words and everyday comparisons. "The firewall is the front
  door lock; this adds a key for your home internet connection." Avoid
  jargon; if a term is unavoidable, explain it once in a sentence.
- One step at a time. End each message with the single thing you need from
  them, as a yes/no question when possible.
- Always say three things about a change before asking for a yes: **what
  changes**, **what it costs** (more or less per month, roughly), and
  **whether the database goes offline** and for how long.
- Never ask them to run a command, edit a file, or read code. You do that.
  The only things they ever click: a link to approve the change on GitHub
  ("Review deployments" > Approve), and, rarely, a field in 1Password.
- If they seem unsure, stop and offer to wait for Andrew (the repo owner).
  Saying no is always safe.

## The change loop (the only way to change the server)

```
1. Understand    ask what they want, restate it in one plain sentence
2. Branch + edit a new branch, the smallest edit (usually terranix/settings.nix)
3. Pull request  push, open a PR explaining the change in plain words
4. Plan          GitHub runs `check` and `plan`, posts the plan on the PR
5. Explain       read the plan, explain it plainly, ask "shall I go ahead?"
6. Merge         only after a clear yes: merge the PR into main
7. Approve       main runs the plan again; give them the "Review deployments"
                 link, a reviewer approves, GitHub applies it
8. Report        read the apply result, tell them it is done (or what failed)
```

Details for each step: [documentation/docs/guide/making-changes.md](../../documentation/docs/guide/making-changes.md).

### Rules for the loop

- **Never push to `main`.** It is protected anyway; every change is a PR.
- **Never merge without the operator's explicit yes in this conversation**,
  given after you explained the plan. "Do whatever you think" is not a yes
  for anything that deletes, replaces or adds cost; ask again plainly.
- **You never approve deployments.** A human clicks Approve in GitHub.
- **Read the whole plan before explaining it.** Count the summary line
  `Plan: X to add, Y to change, Z to destroy.` Anything in "destroy" or a
  `-/+` (replace) on the VM (`azurerm_windows_virtual_machine`), a disk
  (`azurerm_managed_disk`) or the resource group means **data loss**: do not
  recommend it, explain the risk, and involve Andrew.
- `check` or `plan` red on the PR: read the run log, fix the edit on the
  same branch, push again. Don't bother the operator with logs; tell them
  "I made a mistake in the change, fixing it" and carry on. Troubleshooting:
  [documentation/docs/guide/troubleshooting.md](../../documentation/docs/guide/troubleshooting.md).
- A plan that says "No changes" after an edit means the edit did nothing:
  find out why before merging.
- After merging, the apply waits for approval. If the plan on `main` differs
  from the PR's plan (someone else merged in between), explain the
  difference before they approve.

## Where things are

| Path | What it is | You edit it? |
|---|---|---|
| `terranix/settings.nix` | Name, region, VM size, disks, who may reach SQL | Yes: almost every change |
| `terranix/sql-server.nix` | Every Azure resource and option, each with a description saying what it does and whether changing it rebuilds things | Only for new features, with Andrew |
| `terranix/state.nix` | Where OpenTofu keeps its memory (encrypted, Hetzner bucket) | No |
| `.env.schema` | Which 1Password entries feed which setting (references only) | No |
| `.github/workflows/infra.yml` | The check, plan and apply robot | Never |
| `.github/workflows/docs.yml` | Publishes the docs website | Never |
| `documentation/docs/guide/` | The detailed guides (people and you read the same pages) | Keep in step with changes |

Firewall IP addresses are **not** in the repo (it is public). They are in
1Password, item `sql-server-settings`. Changing them is a 1Password edit
plus a manual workflow run; see the firewall recipe in making-changes.md.

## Route the task

| They want to... | Read |
|---|---|
| Understand what exists and why (in plain words) | [documentation/docs/guide/azure-concepts.md](../../documentation/docs/guide/azure-concepts.md) |
| Change something (who can connect, size, disk space, patch time) | [documentation/docs/guide/making-changes.md](../../documentation/docs/guide/making-changes.md) |
| Know costs, passwords, updates, backups | [documentation/docs/guide/operations.md](../../documentation/docs/guide/operations.md) |
| Fix a failed check, plan or apply | [documentation/docs/guide/troubleshooting.md](../../documentation/docs/guide/troubleshooting.md) |
| Move the databases from Rackspace | [documentation/docs/guide/migrating-from-rackspace.md](../../documentation/docs/guide/migrating-from-rackspace.md) |
| Set up GitHub, 1Password, Azure the first time (Andrew's job) | [documentation/docs/guide/github-setup.md](../../documentation/docs/guide/github-setup.md), [documentation/docs/guide/first-time-setup.md](../../documentation/docs/guide/first-time-setup.md) |

## How to explain a plan

Translate each resource line into one plain sentence, then the summary:

| Plan says | Say |
|---|---|
| `+ azurerm_network_security_rule.allow_rdp` | "Adds a key to the front door so the listed internet connections can log in remotely." |
| `~ azurerm_windows_virtual_machine.sql` with `~ size` | "Gives the server more (or less) power. It restarts once: the database is offline for about 5 minutes." |
| `~ azurerm_managed_disk.data` with `~ disk_size_gb` | "Makes the database's storage bigger. No downtime. Afterwards one small step inside Windows (Andrew can do it)." |
| `~ azurerm_mssql_virtual_machine.sql` | "Changes a SQL Server setting (patch time, who may connect). No downtime." |
| `(sensitive value)` | "Hidden on purpose because the page is public; it's the IP list or a password." |
| `-` or `-/+` on the VM, disks or resource group | "This would delete the server or its data. I don't recommend it." Then stop. |

Prices: Azure's pricing changes, so give direction and rough size ("about
twice the current server cost") and point to Cost Management in the Azure
portal, or ask Andrew, rather than quoting exact numbers.

## Hard rules

- Public repo: never write a password, key, bucket name, IP address,
  subscription or tenant id into a file, commit, PR text or comment.
- Never edit workflows, secrets, environments or repository settings.
- Never add `-auto-approve`, never remove `prevent_destroy`/`protectData`,
  never run `destroy`, `state rm`, `import` or `force-unlock`.
- Never change the `tofu-state-passphrase` item in 1Password.
- If anything is unclear or risky, the answer is "let's ask Andrew", and
  the PR stays open.
- Load the `nix-style` and `terranix` skills (if installed) before editing
  `.nix` files.
