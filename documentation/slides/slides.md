# Our database server, moving to Azure

![The old server at Rackspace moves to Microsoft Azure in San Antonio, Texas](diagrams/move.svg)

Note: Press S for the speaker view, F for fullscreen, arrow keys to move. One picture per slide; the notes say it in words.

---

## Written down, not clicked

![Clicking by hand is forgotten and error-prone; a written blueprint is previewed, recorded and repeatable](diagrams/blueprint.svg)

Note: The whole server is described in a file. A program called OpenTofu (the robot) makes Azure match the description. Every change is previewed first and kept in history.

---

## What we get

![Developers pass a firewall to reach the server, which has three disks and sends backups to storage](diagrams/built.svg)

Note: One Windows server with SQL Server, three disks, a firewall that only lets in people on the list, and automatic backups kept 30 days with a copy far away.

---

## How a change happens

![You ask, Claude prepares, GitHub shows a preview, you approve, the robot builds it in Azure](diagrams/change.svg)

Note: Nothing changes until you click Approve. Saying no, or asking Andrew, is always safe.

---

## Where the keys live

![1Password holds the keys to Azure and the server passwords; the robot reads keys and saves passwords; developers get the passwords](diagrams/keys.svg)

Note: Passwords never go into GitHub, email or chat. The project is public. Nobody needs to type or remember the server passwords.

---

## Backups, automatically

![The database is backed up automatically to storage in Texas, kept 30 days, with a copy in Illinois](diagrams/backups.svg)

Note: If something goes wrong, the database can be brought back as it was at almost any minute in the last 30 days.

---

## Letting a developer in

![A developer passes the firewall guest list to reach the server, logging in with a password from 1Password](diagrams/remote.svg)

Note: Add the developer's internet address to the guest list, approve, and share the logins vault with them. Claude walks you through it.

---

## Just ask Claude

![Ask Claude in plain words: add a developer, more disk space, restore a backup, remove it all](diagrams/ask.svg)

Note: Open claude.ai/code, pick the azure-infra project, and ask in your own words. Claude explains what would change, the cost, and waits for your yes.

---

## Your part

![Your three jobs: make the Azure account, put the codes in 1Password, click Approve](diagrams/your-part.svg)

Note: The step-by-step guide is "Getting started" in the documentation website. Claude can walk you through it.

---

## What it costs

![About $385 a month: server and Windows $275, SQL license $25, disks $78, backups and address $9](diagrams/cost.svg)

Note: The documentation's Costs page has the details and is kept up to date with the setup.
