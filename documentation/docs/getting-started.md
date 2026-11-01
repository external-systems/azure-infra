# Getting started (no experience needed)

From nothing to a running database server, in a web browser, about
**2 hours**, once. You install nothing: GitHub's robot does the technical
work. You fill in the human parts: an Azure account with your card, and a
few codes in 1Password. Andrew has already prepared GitHub.

## Easiest: let Claude guide you

1. Open <https://claude.ai/code>, sign in, and **Connect GitHub** when asked.
2. Choose the repository `external-systems/azure-infra`.
3. Type: **"Help me get started with azure-infra from the beginning. I
   have no Azure account and I am not technical."**

Claude walks you through this page one step at a time and explains what
you see.

!!! warning "The one rule"
    Passwords, keys, secrets and tokens go **only into 1Password**: never
    into GitHub, an email, or the chat with Claude. The project is public.

Nothing here can break anything; the build (step 6) waits for your "yes".

## Words you will see

| Word | Means |
|---|---|
| Azure, portal | Microsoft's cloud, where we rent the server; its website is <https://portal.azure.com> |
| Subscription | Your Azure billing account |
| Resource group | A folder in Azure for related things |
| Vault | A folder in 1Password |
| Service account, token | A key that lets the robot open a vault |
| Service principal | The robot's own login to Azure |
| GitHub Actions | The robot that builds and changes the server |
| OpenTofu | The program the robot builds with |
| State | The robot's notebook of what it built |
| Plan / Apply | The robot's preview of a change / making it, after your **Approve** |
| Pull request (PR) | A proposed change, waiting for your yes |
| Remote Desktop (RDP) | Using the server's screen from your computer |

## You need

- [ ] A web browser, your email and phone (for codes)
- [ ] A credit card: Azure bills about **$385 a month** ([costs](guide/costs.md))
- [ ] Your company's **1Password Business** account, as owner or administrator
- [ ] A **GitHub** account (<https://github.com/signup>), added by Andrew as Admin

??? info "Behind the scenes: how it works"
    The GitHub project is a written description of the server (size,
    region, disks, who may connect). **OpenTofu** compares it with Azure and
    makes Azure match; GitHub Actions runs it for you. Every change is first
    a **plan**, and becomes real only after you click **Approve**. The robot
    fetches its keys from 1Password on each run and saves the passwords it
    creates back into 1Password.

## Step 1: Two vaults in 1Password

1. Sign in at <https://my.1password.com>. Click **New vault**, name it
   `azure-infra`, **Create**.
2. Make a second one: `azure-infra-logins`.
3. In each vault: **People** (or **Manage access**) > add Andrew.

**Adding an entry** (used below): open vault `azure-infra` > **+ New
Item** > **Password**, type the title, then for each field **+ Add More** >
**Text** (or **Password** for secrets), type the label exactly as shown
(small letters, underscores), paste the value, **Save**.

??? info "Behind the scenes"
    `azure-infra` holds the keys to Azure: only you, Andrew and the robot.
    `azure-infra-logins` will hold the server's passwords, which the robot
    creates; developers get access to this one only.

## Step 2: Azure account

1. Go to <https://azure.microsoft.com/free> > **Start free**. Sign in with
   (or create) a Microsoft account. Complete the phone and card checks.
2. Open <https://portal.azure.com>. Search **Subscriptions** > your
   subscription > **Upgrade** > **Pay-As-You-Go**.
3. Search **Budgets** > **+ Add**: `450` dollars a month, your email,
   **Create**. (It only sends emails.)
4. Search **Quotas** > **Compute**, region **South Central US**, search
   `DSv5`: **Standard DSv5 Family vCPUs** must allow at least **4**. If
   not, click the pencil and request `8`.

??? info "Behind the scenes"
    The sign-up creates a **tenant** (your organization's directory) and a
    **subscription** (what Azure bills). The server goes into the **South
    Central US** region (San Antonio, Texas).

## Step 3: Paste one line in Azure

1. In the portal, click **>_** at the top right (Cloud Shell). Choose
   **Bash**; for storage, **No storage account required** > **Apply**.
2. Copy this line, paste it into the black panel (right-click > Paste) and
   press **Enter**:

    ```sh
    curl -fsSL https://raw.githubusercontent.com/external-systems/azure-infra/main/scripts/azure-bootstrap.sh | bash
    ```

3. After a minute or two it shows five values. **Right away** (the secret
   is shown once), make the entry `azure-service-principal` with four
   fields, copying the part after each colon:

    | Label | Type |
    |---|---|
    | `subscription_id` | Text |
    | `tenant_id` | Text |
    | `client_id` | Text |
    | `client_secret` | Password |

4. Keep `state_storage_account` for step 4. Type `clear`, **Enter**, close
   the panel.

Something went wrong, or lost the secret? Paste the line again; it is safe.

??? info "Behind the scenes: what the line did"
    It ran a short public script
    ([`scripts/azure-bootstrap.sh`](https://github.com/external-systems/azure-infra/blob/main/scripts/azure-bootstrap.sh))
    as you, inside Azure. It switched on the services the server needs,
    made the robot's notebook (a private storage account in
    `rg-azure-infra-state`, copied to a second region, old versions kept 30
    days), and made the robot's login (service principal
    `azure-infra-tofu`, allowed to build in your subscription).

## Step 4: Two more entries

Both in vault `azure-infra`:

1. `tofu-state-passphrase`: click the dice in the password field, maximum
   length, **Save**. **Never change or delete it.**
2. `sql-server-settings`, three Text fields:

    | Label | Value |
    |---|---|
    | `state_storage_account` | from step 3 |
    | `rdp_source_cidrs` | your home address from <https://ifconfig.me> plus `/32`, e.g. `203.0.113.7/32`; or empty |
    | `sql_source_cidrs` | empty |

??? info "Behind the scenes"
    The notebook holds the server's passwords, so it is encrypted with
    `tofu-state-passphrase`. The settings are private but not passwords:
    the notebook's name, and who may pass the server's firewall
    (`rdp_source_cidrs` for Remote Desktop; developers are added later).

## Step 5: Give the robot its keys

**In 1Password** (<https://my.1password.com> > **Developer** > **Service
Accounts** > **New Service Account**), make two:

| Name | `azure-infra` | `azure-infra-logins` |
|---|---|---|
| `azure-infra-plan` | Read | Read |
| `azure-infra-apply` | Read | Read and Write |

Each shows a token (`ops_...`): **Save in 1Password**, in your *Private*
vault. Access cannot be changed later; if wrong, delete and remake it. No
**Developer** menu? Ask your 1Password owner for the Administrators role.

**In GitHub** (<https://github.com/external-systems/azure-infra/settings/environments>):

1. **azure-plan** > **Add environment secret**: name
   `OP_SERVICE_ACCOUNT_TOKEN`, value the `azure-infra-plan` token.
2. **azure-production** > the same, with the `azure-infra-apply` token.

??? info "Behind the scenes"
    Environments are locked rooms for the robot. Previews run in
    `azure-plan` with the read-only key. Real changes run in
    `azure-production`, only from `main` and only after you or Andrew
    approves. GitHub hides the tokens and never shows them again.

## Step 6: Build the server

1. GitHub > **Actions** > **Infrastructure** > **Run workflow** (`main`) >
   **Run workflow**.
2. Open the run. When `plan` is green, click it: it should say about
   `Plan: 17 to add, 0 to change, 0 to destroy.` Claude can explain it.
3. **Review deployments** > tick `azure-production` > **Approve and
   deploy**. This is your "yes".
4. `apply` takes **15 to 25 minutes**. Green means done.
5. Vault `azure-infra-logins` now has `sql-web-01 Windows admin` and
   `sql-web-01 SQL login`: the server's address and passwords. Nobody ever
   typed or saw them.

Red? Copy the red text to Claude or Andrew.

??? info "Behind the scenes: what was built"
    In resource group `rg-sql-web-01` (see it in the portal): a private
    network, a firewall, a fixed internet address, a Windows Server 2019
    computer with SQL Server 2019 Web edition, three disks, and storage for
    automatic database [backups](guide/backups.md). 1Password invented the
    passwords; the robot set them on the server and noted everything in its
    notebook.

## Step 7: From now on

- **Developers** connect with Remote Desktop:
  [how to let someone in](guide/remote-desktop.md).
- **Any change**: ask Claude at <https://claude.ai/code> (repository
  `external-systems/azure-infra`), in plain words: "What does this cost?",
  "Are the backups working?", "Give Maria Remote Desktop access." Claude
  explains what would change, the cost and any downtime, waits for your
  yes, and you click **Approve** as in step 6.
  More: [For the operator](operator.md).
