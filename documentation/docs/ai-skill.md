# AI assistance

The repo ships an agent skill, `azure-infra`, so that someone new to Azure
can make changes with an AI coding agent (Claude Code, opencode, ...).
The skill explains the setup in plain words, routes the agent to the right
guide page, and holds the safety rules: read every plan with the person,
never apply or delete on its own, never commit a secret or IP address.

| Path | What |
|---|---|
| `skills/azure-infra/SKILL.md` | The skill |
| `.claude/skills/azure-infra` | Link to it, so Claude Code finds it automatically |
| `AGENTS.md` (and `CLAUDE.md`) | Repo rules every agent reads first |
| `documentation/docs/guide/` | The detailed guides; the skill reads the same pages you do |

## Using it

Open the repo in your agent, inside the devenv shell, and ask in your own
words, for example:

- "What does this repo build, and what does it cost to run?"
- "Let my home IP connect with Remote Desktop."
- "The web servers at Rackspace need to reach the database. What do I do?"
- "Make the server bigger; what happens to the database while it resizes?"
- "`plan` says 1 to destroy. Is that OK?"
- "apply failed with SkuNotAvailable."

The agent edits the files, runs `fmt`, `check` and `plan`, explains the
plan, and leaves `apply` and the PR to you unless you ask.

## Keeping it current

When you change how the repo works (a new option, a new secret, a new
procedure), update the matching guide page and, if the routing or rules
change, `SKILL.md`. Both are reviewed in the same PR as the code.
