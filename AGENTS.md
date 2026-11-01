# AGENTS.md

external-systems/azure-infra builds one Windows Server 2019 VM with SQL
Server 2019 Web edition on Azure (network, NSG, data disks, SQL IaaS
registration) with terranix and OpenTofu. Credentials and private values
are in 1Password, loaded by Varlock from `.env.schema`; state is encrypted
(OpenTofu state encryption) in a private Hetzner S3 bucket. **Public repo:
no secret, bucket name, IP address, subscription or tenant id in any file,
commit or PR.** Load the `azure-infra` skill (`skills/azure-infra/`) for
any task here.

## Layout
- `flake.nix`: consumer-facing inputs (all follow external-systems/pkgs; terranix) and the dev partition wiring.
- `flake-parts/terranix.nix`: the `sql-server` terranix configuration, OpenTofu with the azurerm and 1Password providers, the wrapper (`packages.tofu`), `packages.op`.
- `terranix/`: terranix modules. `settings.nix` (values), `sql-server.nix` (resources and options), `state.nix` (backend, encryption), `load-secrets.nix` (Varlock shell run before tofu).
- `.env.schema`: Varlock schema, `op://` references only. `.env` is local and git-ignored.
- `skills/azure-infra/`: the agent skill; `.claude/skills/azure-infra` links to it.
- `dev/flake.nix` + `dev/flake.lock`: dev-only inputs. `dev/flake-module.nix`: the dev partition (formatter, checks, apps, docs); `dev/checks.nix`: offline `tofu validate`.
- `devenv.yaml` + `devenv.lock` + `devenv.nix`: the dev shell (org shell from `org-pkgs/devenv`, plus `plan`, `apply`, `tofu`, `env-check`).
- `documentation/`: MkDocs site (`docs/`, guides in `docs/guide/`, also the skill's references) and reveal.js deck (`slides/`).
- `.vscode/`: nixd settings.

## Tool loop
- The shell is devenv. If `DEVENV_ROOT` is unset, run commands with `devenv shell -- <cmd>`.
- `git add` new files before any `nix` command.
- `fmt`, then `check`. Both must pass before a change is done.
- `plan` before proposing any infrastructure change; summarize it for the person.
- After `nix flake update org-pkgs`, run `sync-locks` in the same commit.

## Rules
- Load the `nix-style` skill before editing any `.nix` file.
- Dev-only inputs go in `dev/flake.nix`, never `flake.nix`.
- Never run `apply`, `destroy`, `state rm`, `import` or `force-unlock` without the person's explicit go-ahead for that command.
- Never print secret values; `env-check` shows them redacted.
- Keep `documentation/docs/guide/` and `skills/azure-infra/SKILL.md` in step with code changes.
- Work on a branch and open a PR. Never push to `main`.
