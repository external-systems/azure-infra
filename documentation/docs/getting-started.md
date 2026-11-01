# Getting started (no experience needed)

This page takes you from **nothing** (no Azure account, no technical
knowledge) to a running database server. You only need a **web browser**.
You never install anything. GitHub's robot (GitHub Actions) does all the
technical work for you.

Plan about **1 to 2 hours**, once. Do the steps in order. Each step says
exactly what to click and what to type.

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
    key, secret or token. Those go only into 1Password.

Nothing on this page can break anything until the step 6 build, and even
that waits for your "yes". Stuck? Ask Claude or Andrew.

## What you will need

- [ ] A computer with a web browser (Chrome, Edge, Safari or Firefox)
- [ ] An email address and your phone (for codes)
- [ ] A credit card (Azure checks your identity with it)
- [ ] A **1Password** account (the password manager). Andrew can invite you.
- [ ] A **GitHub** account with access to this project. Andrew can invite you.

## The big picture

You will do seven steps, and write the important codes into 1Password:

| Step | What | Like... |
|---|---|---|
| 1 | A safe in 1Password | A locked drawer for all the keys |
| 2 | An Azure account | Renting the building |
| 3 | Paste one line in Azure | Making the robot's key card and its notebook |
| 4 | Two more entries in 1Password | A secret code and a short list of settings |
| 5 | Tell GitHub how to open the safe | Giving the robot the drawer key |
| 6 | Build the server | Pressing "go" and saying "yes" |
| 7 | Talk to Claude | From now on, just ask |

!!! warning "The one rule"
    Codes, passwords and keys go **only into 1Password**. Never paste them
    into GitHub, an email, or a chat with Claude. The project is public:
    anyone on the internet can read it.

## Step 1: Make the safe in 1Password

1. Go to <https://my.1password.com> and sign in.
2. On the left, click **New vault** (or the **+** next to "Vaults").
3. Name it exactly: `azure-infra`. Click **Create**.

Done when: you see an empty vault called `azure-infra`.

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
   and **Create**. The server costs about $385 a month
   ([details](guide/costs.md)).
7. Make sure Azure lets you rent a server this size: search **Quotas**,
   click **Compute**, set Region to **South Central US**, and search
   `DSv5`. The line **Standard DSv5 Family vCPUs** must allow at least
   **4**. If it shows less, click the pencil next to it, ask for `8`, and
   submit. Approval usually takes minutes.

Done when: you can open the Azure portal and see your Pay-As-You-Go
subscription.

## Step 3: Run the setup script

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

5. **Right away**, put the first four into 1Password (the secret is shown
   only once). Title: `azure-service-principal`. Fields:

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

## Step 4: Two more 1Password entries

**A. The storage box's lock code.**

1. In 1Password, **+ New Item** > **Password**. Title: `tofu-state-passphrase`.
2. In the password field, click the **generate** button (dice icon), set
   the length to the maximum, and **Save**.
3. **Never change or delete this item.** Without it, the robot cannot read
   its notes.

**B. The private settings.**

1. In 1Password, **+ New Item** > **Password**. Title: `sql-server-settings`.
2. Fields:

    | Label | Type | Value |
    |---|---|---|
    | `state_storage_account` | Text | the `state_storage_account` value from step 3 |
    | `rdp_source_cidrs` | Text | your home internet address + `/32` (see below) |
    | `sql_source_cidrs` | Text | leave empty |

3. Your home internet address: open <https://ifconfig.me> **at home**. It
   shows something like `203.0.113.7`. Type it with `/32` at the end:
   `203.0.113.7/32`. This lets only your home connect to the server's
   screen. Leave the field empty if nobody should connect yet.

Done when: the `azure-infra` vault has these three items:
`azure-service-principal`, `tofu-state-passphrase`, `sql-server-settings`.

## Step 5: Let GitHub open the safe

GitHub's robot needs a key to the `azure-infra` vault. 1Password calls
these **service accounts**. You make two: one that can only look (for
previews) and one that can write (for real changes).

**A. Make the two keys in 1Password.**

1. Go to <https://my.1password.com>, click **Developer** on the left
   (or open <https://developer.1password.com> > **Service Accounts**), and
   click **New Service Account**.
2. Name `azure-infra-plan`. Vault: `azure-infra` with **Read** only.
   Create. It shows a token starting with `ops_`. Click **Save in
   1Password** (choose your *Private* vault, not `azure-infra`).
3. Again: name `azure-infra-apply`. Vault: `azure-infra` with **Read and
   Write**. Create, and save its token the same way.

If you do not see "Developer" or "Service Accounts", your 1Password plan
may not include them: ask Andrew.

**B. Give the keys to GitHub.** Open the project on GitHub:
<https://github.com/external-systems/azure-infra>, then **Settings** (top
right of the project; you need admin access, ask Andrew).

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

That is the only place a key goes outside 1Password, and GitHub hides it.

The project's other GitHub safety settings (who may make changes, a
protected main branch) are Andrew's job:
[GitHub setup](guide/github-setup.md).

## Step 6: Build the server

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
7. Look in 1Password: there are two new items, `sql-web-01 Windows admin`
   and `sql-web-01 SQL login`. They hold the server's address and its
   passwords. The robot made them; you never had to.

If anything turns red: click it, copy the red text, and give it to Claude
or Andrew.

## Step 7: Talk to Claude from now on

From now on you change the server by **asking Claude in your browser**.

1. Go to <https://claude.ai/code> (as in "Easiest: let Claude guide you"
   at the top).
2. Pick the repository `external-systems/azure-infra`.
3. Ask in plain words, for example:
    - "What is this server and what does it cost each month?"
    - "Let my office internet connect to the server."
    - "Make the server bigger."

Claude makes a proposal, shows you what would change, what it costs, and
whether the database goes offline, and only continues when you say
**yes**. At the end, you click **Approve** on GitHub (like step 6.5).
More about this: [For the operator](operator.md).

## Words you might see

| Word | Means |
|---|---|
| Azure | Microsoft's service where we rent the server |
| Portal | Azure's website, <https://portal.azure.com> |
| Subscription | Your Azure billing account |
| Vault | A folder in 1Password |
| Service account / token | A key that lets a robot open the vault |
| GitHub Actions | The robot that builds and changes the server |
| Plan | The robot's preview: "this is what I would change" |
| Apply | The robot actually making the change, after your Approve |
| Pull request (PR) | A proposed change, waiting for your yes |
