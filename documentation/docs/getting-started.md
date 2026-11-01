# Getting started (no experience needed)

This page takes you from **nothing** (no Azure account, no technical
knowledge) to a running database server. You only need a **web browser**.
You never install anything. GitHub's robot (GitHub Actions) does all the
technical work for you.

Plan about **1 to 2 hours**, once. Do the steps in order. Each step says
exactly what to click and what to type.

!!! tip "Stuck?"
    Stop and ask Claude (see [step 8](#step-8-talk-to-claude-from-now-on))
    or Andrew. Copy what is on your screen into the chat. Nothing on this
    page can break anything until the very last step, and even that step
    waits for your "yes".

## What you will need

- [ ] A computer with a web browser (Chrome, Edge, Safari or Firefox)
- [ ] An email address and your phone (for codes)
- [ ] A credit card (Azure and Hetzner check your identity with it)
- [ ] A **1Password** account (the password manager). Andrew can invite you.
- [ ] A **GitHub** account with access to this project. Andrew can invite you.

## The big picture

You will make four things, and write the important codes into 1Password:

| Step | What | Like... |
|---|---|---|
| 1 | A safe in 1Password | A locked drawer for all the keys |
| 2 | An Azure account | Renting the building |
| 3 | A robot key for Azure | A key card the robot uses to enter the building |
| 4 | A storage box at Hetzner | A notebook where the robot writes what it built |
| 5 | Two more entries in 1Password | A secret code and a short list of settings |
| 6 | Tell GitHub how to open the safe | Giving the robot the drawer key |
| 7 | Build the server | Pressing "go" and saying "yes" |

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
   and **Create**. The server costs about $380 a month
   ([details](guide/costs.md)).
7. Make sure Azure lets you rent a server this size: search **Quotas**,
   click **Compute**, set Region to **South Central US**, and search
   `DSv5`. The line **Standard DSv5 Family vCPUs** must allow at least
   **4**. If it shows less, click the pencil next to it, ask for `8`, and
   submit. Approval usually takes minutes.

Done when: you can open the Azure portal and see your Pay-As-You-Go
subscription.

## Step 3: Make the robot's key for Azure

The robot needs its own login to Azure. You create it by pasting **one
line** into a black box in the browser.

1. In the Azure portal, click the **>_** icon at the top right (Cloud
   Shell). A black panel opens at the bottom.
2. If it asks: choose **Bash**. If it asks about storage, choose **No
   storage account required**, pick your subscription, and click
   **Apply**.
3. Wait until you see a line ending in `$`. Copy this whole line (use the
   copy button on the right of the box), click into the black panel,
   paste it (right-click > Paste, or Ctrl+Shift+V), and press **Enter**:

    ```sh
    SUB=$(az account show --query id -o tsv); az ad sp create-for-rbac --name azure-infra-tofu --role Contributor --scopes /subscriptions/$SUB --query "{subscription_id:'$SUB', tenant_id:tenant, client_id:appId, client_secret:password}" -o yaml
    ```

4. After a few seconds it shows four lines like:

    ```
    client_id: 1a2b3c...
    client_secret: AbC~dEf...
    subscription_id: 9z8y7x...
    tenant_id: 5e6f7g...
    ```

5. **Right away**, put them in 1Password (the secret is shown only once).
   Title: `azure-service-principal`. Fields:

    | Label | Type | Value |
    |---|---|---|
    | `subscription_id` | Text | the `subscription_id` line |
    | `tenant_id` | Text | the `tenant_id` line |
    | `client_id` | Text | the `client_id` line |
    | `client_secret` | Password | the `client_secret` line |

    Copy only the part after `: `.

6. Close the black panel.

Done when: the 1Password item `azure-service-principal` has four filled
fields. (If you lost the secret: paste the same line again; it makes a new
one.)

## Step 4: Make the storage box at Hetzner

The robot keeps a notebook of what it built, locked and encrypted. It
lives in a small storage box at Hetzner (a hosting company). It costs a few
euros a month.

1. Go to <https://console.hetzner.cloud>, sign up or sign in, and open (or
   create) a project.
2. On the left click **Object Storage**, then **Create Bucket**.
3. Location: **Helsinki** (hel1). Name: anything unique, for example
   `azure-infra-state-` followed by a few random letters. Visibility:
   **Private**. Click **Create**.
4. Still in Object Storage, open **S3 Credentials** (or **Security** >
   **S3 credentials**) and click **Generate credentials**. It shows an
   **Access key** and a **Secret key**, only once.
5. In 1Password, title `hetzner-s3-state`. Fields:

    | Label | Type | Value |
    |---|---|---|
    | `access_key_id` | Text | the Access key |
    | `secret_access_key` | Password | the Secret key |

Keep the bucket name handy for the next step.

If Andrew already made the bucket, skip to step 5 and ask him for the
name.

## Step 5: Two more 1Password entries

**A. The notebook's lock code.**

1. In 1Password, **+ New Item** > **Password**. Title: `tofu-state-passphrase`.
2. In the password field, click the **generate** button (dice icon), set
   the length to the maximum, and **Save**.
3. **Never change or delete this item.** Without it, the robot cannot read
   its notebook.

**B. The private settings.**

1. In 1Password, **+ New Item** > **Password**. Title: `sql-server-settings`.
2. Fields:

    | Label | Type | Value |
    |---|---|---|
    | `state_bucket` | Text | the bucket name from step 4 |
    | `rdp_source_cidrs` | Text | your home internet address + `/32` (see below) |
    | `sql_source_cidrs` | Text | leave empty |

3. Your home internet address: open <https://ifconfig.me> **at home**. It
   shows something like `203.0.113.7`. Type it with `/32` at the end:
   `203.0.113.7/32`. This lets only your home connect to the server's
   screen. Leave the field empty if nobody should connect yet.

Done when: the `azure-infra` vault has these four items:
`azure-service-principal`, `hetzner-s3-state`, `tofu-state-passphrase`,
`sql-server-settings`.

## Step 6: Let GitHub open the safe

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

## Step 7: Build the server

1. On GitHub, open the project and click **Actions** (top).
2. On the left click **Infrastructure**. On the right click **Run
   workflow**, keep `main`, click the green **Run workflow**.
3. Wait a minute and click the new run. You see three boxes: `check`,
   `plan`, `apply`. `check` and `plan` turn green in a few minutes.
4. Click **plan** to see what will be built. Near the bottom it says
   something like `Plan: 16 to add, 0 to change, 0 to destroy.` For a first
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

## Step 8: Talk to Claude from now on

From now on you change the server by **asking Claude in your browser**.

1. Go to <https://claude.ai/code> and connect GitHub when it asks.
2. Pick the project `external-systems/azure-infra`.
3. Ask in plain words, for example:
    - "What is this server and what does it cost each month?"
    - "Let my office internet connect to the server."
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
| Vault | A folder in 1Password |
| Service account / token | A key that lets a robot open the vault |
| GitHub Actions | The robot that builds and changes the server |
| Plan | The robot's preview: "this is what I would change" |
| Apply | The robot actually making the change, after your Approve |
| Pull request (PR) | A proposed change, waiting for your yes |
