#!/usr/bin/env bash
# One-time GitHub setup for azure-infra (Andrew, as repo admin). Needs the
# GitHub CLI logged in with admin rights: `gh auth login`.
#
#   scripts/github-setup.sh <reviewer-login> [<reviewer-login> ...]
#
# Example: scripts/github-setup.sh my-login operator-login
#
# Sets up, idempotently (safe to run again):
#   - environment azure-plan, and azure-production (main only, the given
#     reviewers must approve every apply)
#   - github-pages: optionally also allows a branch to publish the docs
#     (PAGES_PREVIEW_BRANCH=<branch>; skipped when unset)
#   - ruleset "protect main": pull requests only, check + plan green, no
#     force push, no deletion
#   - Actions: only GitHub's and DeterminateSystems' actions, read-only
#     token, fork workflows wait for approval
#   - interaction limit: collaborators only, 6 months
#
# It does NOT set the two OP_SERVICE_ACCOUNT_TOKEN secrets: the operator
# pastes them in (getting-started step 5), so the tokens never pass
# through anyone else.
# Details and the reasons: documentation/docs/guide/github-setup.md
set -euo pipefail

R="${REPO:-external-systems/azure-infra}"
PAGES_PREVIEW_BRANCH="${PAGES_PREVIEW_BRANCH:-}"

if [ "$#" -lt 1 ]; then
  echo "usage: $0 <reviewer-login> [<reviewer-login> ...]" >&2
  exit 2
fi

reviewers=""
for login in "$@"; do
  id="$(gh api "users/$login" --jq .id)"
  reviewers="${reviewers:+$reviewers,}{\"type\":\"User\",\"id\":$id}"
  echo "reviewer: $login ($id)"
done

# Adds a branch to an environment's custom deployment branch policies,
# unless it is already there.
allow_branch() {
  local env="$1" branch="$2"
  if gh api "repos/$R/environments/$env/deployment-branch-policies" \
    --jq '.branch_policies[].name' 2>/dev/null | grep -qxF "$branch"; then
    return 0
  fi
  gh api -X POST "repos/$R/environments/$env/deployment-branch-policies" \
    -f name="$branch" -f type=branch --silent
}

echo "environments..."
gh api -X PUT "repos/$R/environments/azure-plan" --silent
gh api -X PUT "repos/$R/environments/azure-production" --silent --input - <<JSON
{
  "reviewers": [$reviewers],
  "prevent_self_review": false,
  "deployment_branch_policy": {"protected_branches": false, "custom_branch_policies": true}
}
JSON
allow_branch azure-production main

if [ -n "$PAGES_PREVIEW_BRANCH" ]; then
  echo "github-pages: allow $PAGES_PREVIEW_BRANCH..."
  if ! allow_branch github-pages "$PAGES_PREVIEW_BRANCH"; then
    echo "  could not add it (github-pages may allow protected branches only):" >&2
    echo "  Settings > Environments > github-pages > Deployment branches and tags" >&2
  fi
fi

echo "ruleset protect main..."
ruleset="$(
  cat <<'JSON'
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
)"
existing="$(gh api "repos/$R/rulesets" --jq '.[] | select(.name == "protect main") | .id')"
if [ -n "$existing" ]; then
  gh api -X PUT "repos/$R/rulesets/$existing" --silent --input - <<<"$ruleset"
else
  gh api -X POST "repos/$R/rulesets" --silent --input - <<<"$ruleset"
fi

echo "Actions permissions..."
gh api -X PUT "repos/$R/actions/permissions" -F enabled=true -f allowed_actions=selected --silent
gh api -X PUT "repos/$R/actions/permissions/selected-actions" --silent --input - <<'JSON'
{"github_owned_allowed": true, "verified_allowed": false, "patterns_allowed": ["DeterminateSystems/*"]}
JSON
gh api -X PUT "repos/$R/actions/permissions/fork-pr-contributor-approval" \
  -f approval_policy=all_external_contributors --silent
gh api -X PUT "repos/$R/actions/permissions/workflow" \
  -f default_workflow_permissions=read -F can_approve_pull_request_reviews=false --silent

echo "interaction limit (collaborators only, 6 months)..."
gh api -X PUT "repos/$R/interaction-limits" -f limit=collaborators_only -f expiry=six_months --silent

cat <<OUT

Done. Still to do by hand:
  - Settings > Collaborators: the operator has Admin (or Write).
  - The Claude GitHub App is installed on $R (for Claude in the browser).
  - The operator adds OP_SERVICE_ACCOUNT_TOKEN to azure-plan and
    azure-production (getting-started step 5).
  - Renew the interaction limit in 6 months (run this script again).
OUT
