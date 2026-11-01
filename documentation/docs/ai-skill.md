# AI assistance

The repo ships an agent skill, `azure-infra`, so that someone who knows
nothing about Azure, Terraform or Linux can change the server by talking to
Claude in a web browser (Claude Code on the web). The skill tells Claude how
to talk to a non-technical operator, how to make every change as a pull
request, how to read the plan GitHub posts, and what it must never do.

| Path | What |
|---|---|
| `skills/azure-infra/SKILL.md` | The skill |
| `.claude/skills/azure-infra` | Link to it, so Claude Code finds it automatically |
| `AGENTS.md` (and `CLAUDE.md`) | Repo rules every agent reads first |
| `documentation/docs/guide/` | The detailed guides; the skill reads the same pages you do |

## The flow

```
operator asks in plain words
  -> Claude edits on a branch, opens a pull request
  -> GitHub Actions: check + plan, plan posted on the pull request
  -> Claude explains the plan, operator says yes
  -> Claude merges to main
  -> GitHub Actions: plan, then apply after a reviewer clicks Approve
  -> Claude reports the result
```

The operator needs a GitHub account with Write access and Claude on the
web connected to this repo. No 1Password, Azure account or installed tools:
CI holds the only credential, a 1Password service account token. Setup:
[GitHub setup](guide/github-setup.md). What the operator sees:
[For the operator](operator.md).

## Keeping it current

When you change how the repo works (a new option, a new secret, a new
procedure), update the matching guide page and, if the routing or rules
change, `SKILL.md`. Both are reviewed in the same pull request as the code.
