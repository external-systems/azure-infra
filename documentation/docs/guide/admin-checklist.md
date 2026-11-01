# Before the operator starts (Andrew's checklist)

The operator's job is only the human parts: the Azure account (with the
credit card), and the codes that go into 1Password. Everything about
GitHub is prepared here first, so the [getting started](../getting-started.md)
guide only asks them to paste two tokens into GitHub.

Do these in order.

- [ ] **Invite the operator to GitHub**: Settings > Collaborators > Add
      people, role **Admin** (needed to paste the two tokens and to approve
      applies).
- [ ] **Invite the operator to 1Password**: the same 1Password account
      (family or team) as you, so you can both see the `azure-infra`
      vaults. Service accounts must be available on that plan
      (Developer > Service Accounts).
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
