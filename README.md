# azure-infra

One Windows Server 2019 VM with SQL Server 2019 Web edition on Azure,
built with [terranix](https://terranix.org) and
[OpenTofu](https://opentofu.org). Credentials and private values live in
1Password and are loaded by [Varlock](https://varlock.dev); the encrypted
state lives in a private Azure storage account. This repo is
public and holds no secrets.

Docs: <https://external-systems.github.io/azure-infra/> (start with
[Getting started](https://external-systems.github.io/azure-infra/getting-started.html)).

Goals: infrastructure as code (the files describe the server, OpenTofu
makes Azure match), easy reviewed changes, no clicking in the Azure portal
after the account exists, and day-to-day changes driven by the
`azure-infra` AI skill. Overview: [the big picture](documentation/docs/big-picture.md).

## Use

Changes go through pull requests; GitHub Actions plans them on the pull
request and applies them on `main` after a reviewer approves the
`azure-production` environment. Nobody needs local tools. Admin setup:
[First-time setup](documentation/docs/guide/first-time-setup.md) and
[GitHub setup](documentation/docs/guide/github-setup.md).

Settings to change: `terranix/settings.nix`. Every option, with what it
does: `terranix/sql-server.nix`.

Locally (optional), in the devenv shell with access to the `azure-infra`
1Password vault:

```sh
devenv allow     # auto-activates the shell on cd (after `devenv hook`)
env-check        # 1Password values reachable? (redacted)
plan             # preview changes in Azure
apply            # apply them (asks for yes)
```

## Docs and AI help

- Published to GitHub Pages from `main` (`.github/workflows/docs.yml`).
  Locally: `docs-build`, then open `result-docs/index.html`, or
  `devenv up` for live docs on :8981 and slides on :8982.
- Agents: the `azure-infra` skill in `skills/azure-infra/` (linked from
  `.claude/skills/`) lets a non-technical operator change the server by
  talking to Claude in the browser.

## Develop

```sh
fmt              # format and lint
check            # nix flake check: lint, lock sync, docs, offline tofu validate
```

Editor: VS Code with the Nix IDE extension uses `.vscode/settings.json`
(nixd hints from this flake's nixpkgs, flake-parts and NixOS options;
alejandra on format). Start it from the devenv shell so `nixd` is on PATH.

License: MIT.
