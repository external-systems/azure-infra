# The big picture

A short explanation of what this project is, why it is built this way,
and how you use it. No technical knowledge needed.

## The goals in one minute

![The old server at Rackspace moves to Microsoft Azure in San Antonio, Texas](diagrams/move.svg)

- **Written down, not clicked.** The whole server setup is described in
  plain files ("infrastructure as code"). The description *is* the server:
  what it says is what exists.
- **Easy to change later.** A change is a small edit to the description,
  previewed before it happens. Nothing is forgotten or done differently
  the second time.
- **No more clicking in the Azure website.** After the account is created
  once, nobody needs the Azure admin website for day-to-day work.
- **Changes by conversation.** You ask Claude in plain English. Claude has
  a built-in guide to this project, prepares the change, explains it, and
  waits for your yes.

## Why a description instead of clicking (OpenTofu)

![Clicking by hand is forgotten and error-prone; a written blueprint is previewed, recorded and repeatable](diagrams/blueprint.svg)

Clicking through the Azure website works once, but nobody remembers
exactly what was clicked, mistakes are easy, and doing it again (or undoing
it) is guesswork.

Here, a program called **OpenTofu** reads the written description and
makes Azure match it, like a builder working from a blueprint. You get:

- **A preview first.** Every change starts as a *plan*: "I will add this,
  change that." Nothing happens until you approve.
- **A history.** Every change is recorded on GitHub: what, when, who
  approved it, and why. Anything can be traced or reversed.
- **No surprises.** If someone changed something by hand, the next plan
  shows it, and it can be put back.
- **Safety locks.** The server and its data disks refuse to be deleted by
  accident.

## Why the secrets are in 1Password

![1Password holds the keys to Azure and the server passwords; the robot reads the keys and saves the passwords; developers get the passwords](diagrams/keys.svg)

Passwords and keys are never written in the project (it is public) and
never typed into chats or emails.

- **One safe place.** Azure keys, the robot's keys and the server's
  passwords all live in 1Password, in two vaults.
- **Nobody has to know a password.** The server's Windows and database
  passwords are invented by 1Password and saved there automatically when
  the server is built.
- **Easy to share and take back.** Give a developer access to the logins
  vault; remove them when they leave. 1Password keeps a history of every
  change.

## What gets built

![Developers pass a firewall to reach the server, which has three disks and sends backups to storage](diagrams/built.svg)

| Piece | In plain words |
|---|---|
| The server | A Windows Server 2019 computer in Microsoft's data center in San Antonio, Texas, running SQL Server 2019 Web edition |
| Three fast disks | One for Windows, one for the database files, one for the database log |
| Private network and firewall | The server sits in its own network; the firewall only lets in the internet addresses you list |
| A fixed internet address | So developers and apps always find the server at the same address |
| Backup storage (blob storage) | Azure's file storage. SQL Server saves automatic backups of every database here, kept 30 days, with a copy in a second region far away ([backups](guide/backups.md)) |
| The robot's notebook | A small, locked storage area where OpenTofu remembers what it built |

About **$385 a month** in total ([costs](guide/costs.md)).

![About $385 a month: server and Windows $275, SQL license $25, disks $78, backups and address $9](diagrams/cost.svg)

## How you use it: just ask

![Ask Claude in plain words: add a developer, more disk space, restore a backup, remove it all](diagrams/ask.svg)

![You ask, Claude prepares, GitHub shows a preview, you approve, the robot builds it in Azure](diagrams/change.svg)

Open Claude at <https://claude.ai/code> with the `external-systems/azure-infra`
project and ask in your own words. Some examples, and what happens:

**"How can I add my developer Abdus to the server so he can remote in?"**
: Claude asks for Abdus's internet address, tells you where to add it in
  1Password, starts the update, and explains the preview ("adds Abdus to
  the firewall guest list; no cost, no downtime"). You approve; then you
  share the logins vault with him. ([Remote Desktop](guide/remote-desktop.md))

**"How do I add more disk space to the SQL database?"**
: Claude proposes the bigger size, says what it costs per month and that
  there is no downtime, and opens the change. You approve; one small step
  inside Windows finishes it.

**"How do I restore a backup?"**
: Claude asks what happened and when, explains the options (usually: get
  the database back as a copy, as it was a minute before the mistake), and
  who does which part. ([Backups and recovery](guide/backups.md))

**"How do we delete the infrastructure entirely, since we are moving to
Kubernetes?"**
: Claude explains the steps for the day you are ready: copy the data out
  and check the copy, keep a final backup, then switch off the safety locks
  and remove everything, as one reviewed, approved change. Because this
  deletes data, it is never done in one go, and Andrew is involved.

You can also just ask to understand: *"What do we have and what does it
cost?"*, *"Explain that plan to me"*, *"Are the backups working?"*. Saying
no, or "let's ask Andrew", is always safe.
