---
name: azure-infra
description: "Help the operator of the external-systems/azure-infra repo understand and change their Azure SQL server through pull requests: one Windows Server 2019 VM with SQL Server 2019 Web edition, built with terranix and OpenTofu, planned and applied by GitHub Actions, secrets in 1Password. The operator may be completely non-technical and works only in a browser. Load for any question or change about this repo, the server, its firewall, size, disks, passwords, costs, a plan on a pull request, a failed run, backups and restores, the move from Rackspace, or getting started from nothing (no Azure account yet, first deploy)."
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

## Getting started from nothing (first-time setup)

If the server does not exist yet (they say "get started", "set up",
"I have no Azure account", or the vaults/environments are missing), you are
their guide through
[documentation/docs/getting-started.md](../../documentation/docs/getting-started.md)
(8 steps). Everything happens in their browser; you cannot click in Azure,
1Password or GitHub settings for them, so you tell them exactly what to
click. The same page is online: <https://external-systems.github.io/azure-infra/getting-started.html>;
give them that link if they want to read along.

- **One step at a time.** Read the page, then give them only the current
  step, in your own simple words, with the links. Wait for "done" and
  check the step's "Done when" with them before moving on. Ask them where
  they are if they come back later.
- **Be transparent.** Each step has a "Behind the scenes" box. After each
  step, offer one or two plain sentences of what just happened and why
  (for example "that line gave the robot its own login to Azure, allowed
  to build things in your account"). Never hide what a step does.
- **Never let a secret into the chat.** Codes, keys, tokens and passwords
  go from the screen straight into 1Password. Say so before steps 3 and 5.
  If they paste one anyway: tell them calmly, and have them make a new one
  (step 3: paste the setup line again; step 5: delete and recreate that
  service account) and update 1Password.
- **Steps 5 and 6 need Admin on the GitHub repo.** If they cannot see
  **Settings** on the repo, stop and ask Andrew to make them Admin (or to
  do those steps).
- **Step 7 (first build):** you may start Actions > Infrastructure > Run
  workflow on `main` for them if you have a tool for it; otherwise guide
  them. Read the `plan` job's output and explain it: a first build is
  only `+` (about 17 resources), roughly $385 a month
  ([costs](../../documentation/docs/guide/costs.md)), nothing to lose yet.
  Then they click **Review deployments** > Approve. You never approve.
- If a step fails, read the error with them, check
  [troubleshooting](../../documentation/docs/guide/troubleshooting.md),
  and if it is not clear, stop and suggest asking Andrew.
- After the first build: show them where the server's address and
  passwords are (1Password vault `azure-infra-logins`, items
  `sql-web-01 Windows admin` and `sql-web-01 SQL login`; OpenTofu created
  and saved them there), then step 8: developers' Remote Desktop access
  ([remote-desktop.md](../../documentation/docs/guide/remote-desktop.md))
  and how future changes work (below).

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
| `terranix/state.nix` | Where OpenTofu keeps its memory (encrypted, in an Azure storage account) | No |
| `.env.schema` | Which 1Password entries feed which setting (references only) | No |
| `.github/workflows/infra.yml` | The check, plan and apply robot | Never |
| `.github/workflows/docs.yml` | Publishes the docs website | Never |
| `documentation/docs/guide/` | The detailed guides (people and you read the same pages) | Keep in step with changes |
| `documentation/docs/guide/costs.md` | Monthly cost estimate for the current settings | Yes: in the same PR as any size, disk, region or image change |

Firewall IP addresses are **not** in the repo (it is public). They are in
1Password, vault `azure-infra`, item `sql-server-settings`. The generated
logins are in vault `azure-infra-logins` (shared with developers; never
share `azure-infra` with them). Changing them is a 1Password edit
plus a manual workflow run; see the firewall recipe in making-changes.md.

## Route the task

| They want to... | Read |
|---|---|
| Understand what exists and why (in plain words) | [documentation/docs/guide/azure-concepts.md](../../documentation/docs/guide/azure-concepts.md) |
| Change something (who can connect, size, disk space, patch time) | [documentation/docs/guide/making-changes.md](../../documentation/docs/guide/making-changes.md) |
| Know what it costs, or what a change would cost | [documentation/docs/guide/costs.md](../../documentation/docs/guide/costs.md) |
| Let a developer (or themselves) log in with Remote Desktop, or remove someone | [documentation/docs/guide/remote-desktop.md](../../documentation/docs/guide/remote-desktop.md) |
| Know how backups work, check them, or get data back | [documentation/docs/guide/backups.md](../../documentation/docs/guide/backups.md) |
| Know passwords, updates | [documentation/docs/guide/operations.md](../../documentation/docs/guide/operations.md) |
| Fix a failed check, plan or apply | [documentation/docs/guide/troubleshooting.md](../../documentation/docs/guide/troubleshooting.md) |
| Move the databases from Rackspace | [documentation/docs/guide/migrating-from-rackspace.md](../../documentation/docs/guide/migrating-from-rackspace.md) |
| Set up everything from zero, browser only (no Azure account yet) | [documentation/docs/getting-started.md](../../documentation/docs/getting-started.md): walk them through it one step at a time |
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

Prices: use the estimate and the "What changes the cost" table in
[costs.md](../../documentation/docs/guide/costs.md), as rough numbers
("about $385 a month now; this makes it about $240"). Any change to region,
VM size, image, disks or public IP also updates costs.md in the same pull
request, and the PR description says how the monthly total changes. For the
real bill, point to Cost Management in the Azure portal.

## Hard rules

- Public repo: never write a password, key, storage account name, IP address,
  subscription or tenant id into a file, commit, PR text or comment.
- Never edit workflows, secrets, environments or repository settings.
- Never add `-auto-approve`, never remove `prevent_destroy`/`protectData`,
  never run `destroy`, `state rm`, `import` or `force-unlock`.
- Never change the `tofu-state-passphrase` item in 1Password.
- If anything is unclear or risky, the answer is "let's ask Andrew", and
  the PR stays open.
- Load the `nix-style` and `terranix` skills (if installed) before editing
  `.nix` files.
