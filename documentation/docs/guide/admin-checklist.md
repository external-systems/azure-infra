# Before the operator starts (Andrew's checklist)

The operator's job is only the human parts: the Azure account (with the
credit card), and the codes that go into 1Password. Everything about
GitHub is prepared here first, so the [getting started](../getting-started.md)
guide only asks them to paste two tokens into GitHub.

Do these in order.

- [ ] **Invite the operator to GitHub**: Settings > Collaborators > Add
      people, role **Admin** (needed to paste the two tokens and to approve
      applies).
- [ ] **1Password**: the vaults live in the operator's company **1Password
      Business** account (they create them in step 1 and add you to both).
      Make sure they can create vaults and service accounts there (owner or
      Administrators role); if not, the company's 1Password owner grants it
      or does step 5A. For local runs you need a seat in that account:
      `OP_ACCOUNT` is its sign-in address.
- [ ] **Install the Claude GitHub App** on this repo
      (<https://github.com/apps/claude>), so Claude in the browser
      (claude.ai/code) can open pull requests for the operator.
- [ ] **Run the GitHub setup script** once, from a checkout, with `gh`
      logged in as an admin. Give it every person who may approve an apply
      (you and the operator, by GitHub login):

    ```sh
    scripts/github-setup.sh <your-login> <operator-login>
    ```

    It creates the `azure-plan` and `azure-production` environments
    (reviewers, main only), lets the setup branch publish the docs, adds
    the `protect main` ruleset, locks down Actions, and limits interactions
    to collaborators for 6 months. What each setting does:
    [GitHub setup](github-setup.md). Safe to run again.

- [ ] **Merge the setup pull request** into `main`. Step 3 of getting
      started downloads `scripts/azure-bootstrap.sh` from `main`, and
      Actions only offers **Run workflow** for workflows on `main`. Before
      the tokens exist, the merge changes nothing in Azure: `plan` fails at
      "Check the 1Password token is configured" and `apply` never runs.
- [ ] **Send the operator the link**:
      <https://external-systems.github.io/azure-infra/getting-started.html>.
      They start Claude at claude.ai/code and say "Help me get started".

After the merge: remove the setup branch from `.github/workflows/docs.yml`
and from Settings > Environments > github-pages.

When the operator reaches step 7 (the first build), you can approve the
deployment yourself if they prefer: any listed reviewer can.

Every 6 months: run `scripts/github-setup.sh` again to renew the
interaction limit.
