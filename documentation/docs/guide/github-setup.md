# GitHub setup (admin, once)

How the repo's GitHub side is locked down so that changes only reach Azure
through reviewed pull requests, only people you invite can trigger
anything, and CI needs no tools on anyone's computer. Run these once as a
repo admin, with the GitHub CLI (`gh auth login`) or in the web settings.
They are settings, not files, so they are not in the repo.

`OWNER/REPO` below is `external-systems/azure-infra`.

**Shortcut:** `scripts/github-setup.sh <your-login> <operator-login>` does
sections 2 (without the secrets), 3, 4 and the interaction limit from 5 in
one run. The order of everything to do before the operator starts is in
the [admin checklist](admin-checklist.md). The sections below explain each
setting.

## How the pipeline works

```
branch -> pull request --(Infrastructure: check, plan)--> plan posted on the PR
                                      | operator reads it and says yes
merge to main --(check, plan)--> apply waits for "Review deployments"
                                      | required reviewer approves
                               tofu apply of exactly that plan
```

- `.github/workflows/infra.yml`: `check` (flake check), `plan`, and on
  `main` only, `apply` in the `azure-production` environment.
- `.github/workflows/docs.yml`: builds the docs and publishes them to
  GitHub Pages on every push to `main`.
- Manual run (Actions > Infrastructure > Run workflow, on `main`): plan and
  apply without a code change, e.g. after editing firewall IPs in 1Password.

## 1. 1Password service accounts

Create two (1Password.com > Developer > Service Accounts). Vault access
cannot be changed after creation.

| Service account | `azure-infra` | `azure-infra-logins` | Used by |
|---|---|---|---|
| `azure-infra-plan` | read | read | `plan` on pull requests and on `main` |
| `azure-infra-apply` | read | read and write (saves the generated logins) | `apply` |

## 2. Environments and secrets

The 1Password token is the only secret GitHub holds, and only inside
environments, so a job outside them never sees it.

```sh
R=external-systems/azure-infra

# plan: runs on any same-repo branch
gh api -X PUT repos/$R/environments/azure-plan
gh secret set OP_SERVICE_ACCOUNT_TOKEN --env azure-plan --repo $R   # azure-infra-plan token

# apply: main only, a required reviewer must approve every run
gh api -X PUT repos/$R/environments/azure-production --input - <<'JSON'
{
  "reviewers": [{"type": "User", "id": 203035778}],
  "prevent_self_review": false,
  "deployment_branch_policy": {"protected_branches": false, "custom_branch_policies": true}
}
JSON
gh api -X POST repos/$R/environments/azure-production/deployment-branch-policies -f name=main -f type=branch
gh secret set OP_SERVICE_ACCOUNT_TOKEN --env azure-production --repo $R   # azure-infra-apply token
```

Add more reviewers (for example the operator) with their user ids:
`gh api users/<login> --jq .id`. Any one reviewer approving is enough.

## 3. Protect `main`

A ruleset: no direct pushes, no force pushes, no deletion, every change
through a pull request whose `check` and `plan` jobs passed.

```sh
gh api -X POST repos/$R/rulesets --input - <<'JSON'
{
  "name": "protect main",
  "target": "branch",
  "enforcement": "active",
  "conditions": {"ref_name": {"include": ["~DEFAULT_BRANCH"], "exclude": []}},
  "bypass_actors": [],
  "rules": [
    {"type": "deletion"},
    {"type": "non_fast_forward"},
    {"type": "pull_request", "parameters": {
      "required_approving_review_count": 0,
      "dismiss_stale_reviews_on_push": true,
      "require_code_owner_review": false,
      "require_last_push_approval": false,
      "required_review_thread_resolution": false
    }},
    {"type": "required_status_checks", "parameters": {
      "strict_required_status_checks_policy": true,
      "required_status_checks": [{"context": "check"}, {"context": "plan"}]
    }}
  ]
}
JSON
```

`required_approving_review_count: 0` lets the operator merge their own
pull request (GitHub never lets authors approve their own). The real gate
is the `azure-production` approval before anything changes in Azure. If
you want to approve every pull request yourself as well, set it to `1`
and the operator's pull requests wait for your review.

## 4. Actions: only your people, only trusted actions

```sh
# Only GitHub's own actions and DeterminateSystems (Nix) may run
gh api -X PUT repos/$R/actions/permissions -F enabled=true -f allowed_actions=selected
gh api -X PUT repos/$R/actions/permissions/selected-actions --input - <<'JSON'
{"github_owned_allowed": true, "verified_allowed": false, "patterns_allowed": ["DeterminateSystems/*"]}
JSON

# Workflows from forks of anyone who is not a collaborator never start without your approval
gh api -X PUT repos/$R/actions/permissions/fork-pr-contributor-approval -f approval_policy=all_external_contributors

# The default token is read-only and may not approve pull requests
gh api -X PUT repos/$R/actions/permissions/workflow -f default_workflow_permissions=read -F can_approve_pull_request_reviews=false
```

## 5. Who can open pull requests

On a public repo GitHub lets anyone fork and open a pull request; there is
no setting that forbids it permanently. What keeps them out:

- **Write access only for your people**: Settings > Collaborators, add the
  operator with the *Write* role. Only they can push branches here; everyone
  else can only open pull requests from forks.
- **Forks never use your CI**: every job in `infra.yml` skips pull requests
  from forks, fork runs get no secrets, and section 4 holds any fork
  workflow for your approval. Never approve one; never add
  `pull_request_target` to a workflow.
- **Block outsiders from opening anything**: interaction limits, renewable
  every six months:

  ```sh
  gh api -X PUT repos/$R/interaction-limits -f limit=collaborators_only -f expiry=six_months
  ```

  Until they expire, only collaborators can open issues or pull requests
  or comment. Set a reminder to renew.

## 6. Pages

Settings > Pages > Source: **GitHub Actions** (done). The `docs` workflow
publishes on the next push to `main`; the URL appears on the workflow run
and in Settings > Pages.

## 7. The operator's Claude

The operator works in Claude in the browser (Claude Code on the web,
claude.ai/code) with this repo. Their GitHub account needs Write access
(section 5) and the Claude GitHub App installed on the repo. They need no
1Password, Azure or local tools: CI does all of that. The `azure-infra`
skill tells Claude how to work with them.

## What is still trusted

People with Write access can change workflows on a branch, and a branch's
`plan` job sees the `azure-infra-plan` token, which can read the Azure
service principal. Only give Write access to people you would trust with
Azure itself. For more separation later: a second, read-only Azure service
principal for plans, in its own vault.
