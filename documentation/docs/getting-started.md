# Getting started (no experience needed)

This page takes you from **nothing** (no Azure account, no technical
knowledge) to a running database server. You only need a **web browser**.
You never install anything. GitHub's robot (GitHub Actions) does all the
technical work; you only fill in the human parts: your details, a credit
card, and a few codes that go into 1Password.

Plan about **2 hours**, once. Do the steps in order. Each step says exactly
what to click and what to type, and has a **Behind the scenes** box you can
open if you are curious what is really going on. You never *need* to read
those.

## Easiest: let Claude guide you

Open Claude in a second browser tab and let it walk you through this page,
one step at a time:

1. Go to <https://claude.ai/code> and sign in. When it asks, click
   **Connect GitHub** and allow it.
2. Choose the repository `external-systems/azure-infra`.
3. Type: **"Help me get started with azure-infra from the beginning. I
   have no Azure account and I am not technical."**

Claude knows this project (it has a guide built in). It tells you what to
click, waits for you, and explains anything you see. You can also just read
this page on your own: the steps are the same.

!!! warning "Never paste codes into the chat"
    Show Claude error messages and what you see, but **never** a password,
    key, secret or token. Those go only into 1Password. The project is
    public: anyone on the internet can read it.

Nothing on this page can break anything until the step 7 build, and even
that waits for your "yes". Stuck? Ask Claude or Andrew.

## What you will need

- [ ] A computer with a web browser (Chrome, Edge, Safari or Firefox)
- [ ] An email address and your phone (for codes)
- [ ] A credit card (Azure checks your identity with it, and bills it
      monthly, about $385; see [costs](guide/costs.md))
- [ ] A **1Password** account (the password manager). Andrew invites you
      to the family or team account.
- [ ] A **GitHub** account (free, <https://github.com/signup>). Andrew adds
      you to this project as **Admin**.

## The big picture

| Step | What | Like... |
|---|---|---|
| 1 | Two safes in 1Password | A locked drawer for the keys, and one for the server's logins |
| 2 | An Azure account | Renting the building |
| 3 | Paste one line in Azure | Making the robot's key card and its notebook |
| 4 | Two more entries in 1Password | A secret code and a short list of settings |
| 5 | Give GitHub's robot a key to the safe | Handing the robot the drawer key |
| 6 | Lock the GitHub project | Only your people can make changes |
| 7 | Build the server | Pressing "go" and saying "yes" |
| 8 | Let developers in, and talk to Claude | From now on, just ask |

??? info "Behind the scenes: how the whole thing works"
    The project on GitHub is a **written description** of the server: what
    size it is, which region, which disks, who may connect. Nobody builds
    it by clicking in Azure. Instead, a program called **OpenTofu** reads
    the description, compares it with what exists in Azure, and makes Azure
    match. GitHub's robot (GitHub Actions) runs OpenTofu for you, so nothing
    runs on your computer.

    Every change is first a **plan** ("this is what I would do"), which you
    read (or Claude explains), and only becomes real after you click
    **Approve**. The robot gets its keys from 1Password every time it runs,
    and saves the passwords it creates back into 1Password.

## Step 1: Make two safes (vaults) in 1Password

1. Go to <https://my.1password.com> and sign in.
2. On the left, click **New vault** (or the **+** next to "Vaults").
3. Name it exactly: `azure-infra`. Click **Create**.
4. Make a second one the same way, named exactly: `azure-infra-logins`.

Done when: you see two empty vaults, `azure-infra` and
`azure-infra-logins`.

??? info "Behind the scenes: why two?"
    `azure-infra` holds the keys to Azure itself: only you, Andrew and the
    robot open it. `azure-infra-logins` will hold the server's Windows and
    database passwords, which the robot creates. Developers who need to log
    in to the server get access to that one only.

**How to add an entry** (you will do this several times below):

1. Open the `azure-infra` vault, click **+ New Item**, choose **Password**.
2. Type the **title** this page tells you.
3. For each field: click **+ Add More** > **Text** (or **Password** for
   secret ones), click the field's label and type the **label** exactly
   as written (small letters and underscores, no spaces), then paste the
   value.
4. Click **Save**.

Labels must be spelled exactly as shown, or the robot cannot find them.

## Step 2: Make an Azure account

Azure is Microsoft's cloud: you rent a computer there by the hour.

1. Go to <https://azure.microsoft.com/free> and click **Start free** (or
   **Try Azure for free**).
2. Sign in with a Microsoft account, or click **Create one** to make one
   with your email.
3. Fill in your details, the phone check, and the card check. You are not
   charged for signing up.
4. When it says you are ready, go to <https://portal.azure.com>. This is
   the Azure website ("the portal").
5. Turn the free trial into a normal account, so the server is allowed to
   run: in the search bar at the top type **Subscriptions**, click it,
   click your subscription, then click **Upgrade**. Choose
   **Pay-As-You-Go** and confirm.
6. Protect yourself from surprise bills: search **Budgets**, click
   **+ Add**, amount `450` (dollars per month), add your email for alerts,
   and **Create**.
7. Make sure Azure lets you rent a server this size: search **Quotas**,
   click **Compute**, set Region to **South Central US**, and search
   `DSv5`. The line **Standard DSv5 Family vCPUs** must allow at least
   **4**. If it shows less, click the pencil next to it, ask for `8`, and
   submit. Approval usually takes minutes.

Done when: you can open the Azure portal and see your Pay-As-You-Go
subscription.

??? info "Behind the scenes"
    The sign-up creates a **tenant** (your organization's directory of
    people) and a **subscription** (the account Azure bills). Everything
    the robot builds goes into that subscription, in the **South Central
    US** region (San Antonio, Texas). The budget only sends emails; it never
    switches anything off.

## Step 3: Paste one line in Azure

The robot needs two things in Azure: its own **login** (a key card), and a
small locked **storage box** where it writes down what it built. One
pasted line makes both.

1. In the Azure portal, click the **>_** icon at the top right (Cloud
   Shell). A black panel opens at the bottom.
2. If it asks: choose **Bash**. If it asks about storage, choose **No
   storage account required**, pick your subscription, and click
   **Apply**.
3. Wait until you see a line ending in `$`. Copy this line (use the copy
   button on the right of the box), click into the black panel, paste it
   (right-click > Paste, or Ctrl+Shift+V), and press **Enter**:

    ```sh
    curl -fsSL https://raw.githubusercontent.com/external-systems/azure-infra/main/scripts/azure-bootstrap.sh | bash
    ```

4. It works for a minute or two, then shows a box like this:

    ```
    ==================== copy these into 1Password ====================
    Item azure-service-principal:
      subscription_id:        9z8y7x...
      tenant_id:              5e6f7g...
      client_id:              1a2b3c...
      client_secret:          AbC~dEf...
    Item sql-server-settings:
      state_storage_account:  tfstate1a2b3c4d5e
    ===================================================================
    ```

5. **Right away**, put the first four into 1Password, vault `azure-infra`
   (the secret is shown only once). Title: `azure-service-principal`.
   Fields:

    | Label | Type | Value |
    |---|---|---|
    | `subscription_id` | Text | the `subscription_id` value |
    | `tenant_id` | Text | the `tenant_id` value |
    | `client_id` | Text | the `client_id` value |
    | `client_secret` | Password | the `client_secret` value |

    Copy only the part after the colon and spaces.

6. Keep the `state_storage_account` value for step 4. Then type `clear`,
   press **Enter**, and close the black panel.

Done when: the 1Password item `azure-service-principal` has four filled
fields. If something went wrong or you lost the secret, paste the same line
again: it is safe to run twice.

??? info "Behind the scenes: what that line did"
    It downloaded a short, public script from this project
    ([`scripts/azure-bootstrap.sh`](https://github.com/external-systems/azure-infra/blob/main/scripts/azure-bootstrap.sh))
    and ran it as you, inside Azure. It:

    - switched on the Azure services the server needs (compute, network,
      storage, SQL);
    - made a resource group `rg-azure-infra-state` with a private storage
      account: the robot's notebook (the "state"), copied to a second
      region and with 30 days of old versions kept;
    - made a **service principal** called `azure-infra-tofu`: a login for
      a program instead of a person, allowed to build things in your
      subscription (role "Contributor"). The four values are its user
      name (`client_id`), password (`client_secret`) and which Azure
      account it belongs to.

## Step 4: Two more 1Password entries

Both in vault `azure-infra`.

**A. The notebook's lock code.**

1. **+ New Item** > **Password**. Title: `tofu-state-passphrase`.
2. In the password field, click the **generate** button (dice icon), set
   the length to the maximum, and **Save**.
3. **Never change or delete this item.** Without it, the robot cannot read
   its notes.

**B. The private settings.**

1. **+ New Item** > **Password**. Title: `sql-server-settings`.
2. Fields:

    | Label | Type | Value |
    |---|---|---|
    | `state_storage_account` | Text | the `state_storage_account` value from step 3 |
    | `rdp_source_cidrs` | Text | your home internet address + `/32` (see below), or empty |
    | `sql_source_cidrs` | Text | leave empty |

3. Your home internet address: open <https://ifconfig.me> **at home**. It
   shows something like `203.0.113.7`. Type it with `/32` at the end:
   `203.0.113.7/32`. Leave the field empty if nobody needs to log in to
   the server's screen yet; developers are added later (step 8).

Done when: the `azure-infra` vault has these three items:
`azure-service-principal`, `tofu-state-passphrase`, `sql-server-settings`.

??? info "Behind the scenes"
    The robot's notebook contains the server's passwords, so it is locked
    (encrypted) with `tofu-state-passphrase` before it is saved. The
    settings item holds things that are not passwords but must not be
    public: the notebook's address and the internet addresses allowed
    through the server's firewall (`rdp_source_cidrs` for Remote Desktop,
    `sql_source_cidrs` for direct database connections, off by default).

## Step 5: Give GitHub's robot a key to the safe

1Password calls these keys **service accounts**. You make two: one that
can only look (for previews) and one that can also save the server's
passwords (for real changes).

**A. Make the two keys in 1Password.**

1. Go to <https://my.1password.com>, click **Developer** on the left
   (or open <https://developer.1password.com> > **Service Accounts**), and
   click **New Service Account**.
2. Name `azure-infra-plan`. Give it the vault `azure-infra` with **Read**,
   and the vault `azure-infra-logins` with **Read**. Create. It shows a
   token starting with `ops_`. Click **Save in 1Password** (choose your
   *Private* vault, not the azure ones).
3. Again: name `azure-infra-apply`. Vault `azure-infra` with **Read**,
   vault `azure-infra-logins` with **Read and Write**. Create, and save its
   token the same way.

Vault access cannot be changed later; if you got it wrong, delete the
service account and make it again. If you do not see "Developer" or
"Service Accounts", ask Andrew.

**B. Give the keys to GitHub.** Open the project:
<https://github.com/external-systems/azure-infra>, then **Settings** (the
gear tab at the top of the project; you need Admin, ask Andrew).

1. Left menu: **Environments** > **New environment**. Name: `azure-plan`.
   **Configure environment**.
2. Under **Environment secrets** click **Add environment secret**. Name:
   `OP_SERVICE_ACCOUNT_TOKEN`. Value: paste the `azure-infra-plan` token.
   **Add secret**.
3. Back to **Environments** > **New environment**. Name:
   `azure-production`. **Configure environment**.
4. Tick **Required reviewers**, add yourself (and Andrew), and click
   **Save protection rules**. Now nothing changes in Azure until one of you
   clicks "Approve".
5. **Deployment branches and tags**: choose **Selected branches and tags**,
   **Add deployment branch or tag rule**, type `main`, **Add rule**.
6. **Add environment secret**: name `OP_SERVICE_ACCOUNT_TOKEN`, value the
   `azure-infra-apply` token. **Add secret**.

Done when: **Environments** lists `azure-plan` and `azure-production`, each
with one secret.

??? info "Behind the scenes"
    An **environment** is a locked room the robot works in. The token is
    the only key GitHub ever holds; GitHub keeps it hidden and gives it only
    to jobs in that room. Previews (plans) run in `azure-plan` with the
    look-only key. Real changes run in `azure-production`, only from the
    `main` branch, and only after a required reviewer approves, with the key
    that may also save passwords.

## Step 6: Lock the GitHub project

The project is public: anyone can read it. These settings make sure only
your people can change it, and that strangers can never use your robot.
All in the project's **Settings**.

**A. Protect the main version** (Settings > **Rules** > **Rulesets**):

1. **New ruleset** > **New branch ruleset**.
2. Ruleset name: `protect main`. Enforcement status: **Active**.
3. Target branches: **Add target** > **Include default branch**.
4. Tick: **Restrict deletions**, **Require a pull request before
   merging** (required approvals: `0`), **Require status checks to pass**
   (tick "Require branches to be up to date"; click **Add checks** and add
   `check` and `plan`), and **Block force pushes**.
5. **Create**.

**B. Control the robot** (Settings > **Actions** > **General**):

1. Actions permissions: **Allow ... and select non-... actions**. Tick
   **Allow actions created by GitHub**, and in the box below type
   `DeterminateSystems/*`.
2. Approval for running fork pull request workflows: **Require approval
   for all external contributors**.
3. Workflow permissions: **Read repository contents and packages
   permissions**. Untick **Allow GitHub Actions to create and approve pull
   requests**.
4. **Save** under each section.

**C. Keep strangers out** (Settings > **Moderation options** >
**Interaction limits**): choose **Limit to repository collaborators**, for
**6 months**. Put a reminder in your calendar to renew it.

**D. Who may make changes** (Settings > **Collaborators and teams**): only
you and Andrew (Admin), and anyone else Andrew says (Write). Developers who
only need Remote Desktop do **not** need GitHub access.

??? info "Behind the scenes"
    `main` is the official version of the description; the robot builds
    from it. With the ruleset, every change has to be a **pull request** (a
    proposed change) whose checks and preview passed. Pull requests from
    strangers' copies ("forks") never get the robot's keys, and the
    interaction limit stops strangers from even opening one. Details for
    Andrew: [GitHub setup](guide/github-setup.md).

## Step 7: Build the server

1. On GitHub, open the project and click **Actions** (top).
2. On the left click **Infrastructure**. On the right click **Run
   workflow**, keep `main`, click the green **Run workflow**.
3. Wait a minute and click the new run. You see three boxes: `check`,
   `plan`, `apply`. `check` and `plan` turn green in a few minutes.
4. Click **plan** to see what will be built. Near the bottom it says
   something like `Plan: 17 to add, 0 to change, 0 to destroy.` For a first
   build, only "add" should be more than 0. Ask Claude to explain it if you
   like.
5. A yellow box says **Review deployments**. Click it, tick
   `azure-production`, and click **Approve and deploy**. This is the "yes".
6. `apply` runs for about **15 to 25 minutes**. Green means done.
7. Look in 1Password, vault `azure-infra-logins`: there are two new items,
   `sql-web-01 Windows admin` and `sql-web-01 SQL login`. They hold the
   server's address and its passwords. The robot made them; nobody ever
   typed or saw those passwords.

If anything turns red: click it, copy the red text, and give it to Claude
or Andrew.

??? info "Behind the scenes: what the robot built"
    In Azure, in a resource group `rg-sql-web-01`: a private network, a
    firewall, a fixed public internet address, a Windows Server 2019
    computer with SQL Server 2019 Web edition, three fast disks (Windows,
    database files, database log), and a storage account for automatic
    database backups ([backups](guide/backups.md)). It asked 1Password to
    invent the Windows and database passwords and save them in
    `azure-infra-logins`, then set them on the server. Finally it wrote
    everything it did into its locked notebook, so next time it knows what
    already exists. You can look at all of it in the Azure portal: search
    **Resource groups** > `rg-sql-web-01`.

## Step 8: Let developers in, and talk to Claude

**Developers** connect to the server with Remote Desktop. To let one in,
you add their internet address and share the logins vault:
[Remote Desktop](guide/remote-desktop.md). Claude can walk you through it:
*"Give Maria Remote Desktop access."*

**Any other change**, ask Claude in your browser:

1. Go to <https://claude.ai/code> (as in "Easiest: let Claude guide you"
   at the top).
2. Pick the repository `external-systems/azure-infra`.
3. Ask in plain words, for example:
    - "What is this server and what does it cost each month?"
    - "Are the backups working?"
    - "Make the server bigger."

Claude makes a proposal, shows you what would change, what it costs, and
whether the database goes offline, and only continues when you say
**yes**. At the end, you click **Approve** on GitHub (like step 7.5).
More about this: [For the operator](operator.md).

## Words you might see

| Word | Means |
|---|---|
| Azure | Microsoft's service where we rent the server |
| Portal | Azure's website, <https://portal.azure.com> |
| Subscription | Your Azure billing account |
| Resource group | A folder in Azure that holds related things |
| Vault | A folder in 1Password |
| Service account / token | A key that lets a robot open a vault |
| Service principal | The robot's own login to Azure |
| GitHub Actions | The robot that builds and changes the server |
| OpenTofu | The program the robot uses to build from the description |
| State | The robot's notebook of what it built |
| Plan | The robot's preview: "this is what I would change" |
| Apply | The robot actually making the change, after your Approve |
| Pull request (PR) | A proposed change, waiting for your yes |
| Remote Desktop (RDP) | Seeing and using the server's screen from your computer |
