# azure-infra

One Windows Server 2019 VM with SQL Server 2019 Web edition on Azure,
built with [terranix](https://terranix.org) and
[OpenTofu](https://opentofu.org). Credentials and private values live in
1Password and are loaded by [Varlock](https://varlock.dev); the encrypted
state lives in a private Hetzner Object Storage bucket. This repo is
public and holds no secrets.

## Use

Needs Nix and devenv, and access to the `azure-infra` 1Password vault.
First time: [First-time setup](documentation/docs/guide/first-time-setup.md).

```sh
devenv allow     # auto-activates the shell on cd (after `devenv hook`)
env-check        # 1Password values reachable? (redacted)
plan             # preview changes in Azure
apply            # apply them (asks for yes)
tofu output      # public and private IP
```

Settings to change: `terranix/settings.nix`. Every option, with what it
does: `terranix/sql-server.nix`.

## Docs and AI help

- `docs-build`, then open `result-docs/index.html` (guide and slides), or
  `devenv up` for live docs on :8981 and slides on :8982.
- Agents: the `azure-infra` skill in `skills/azure-infra/` (linked from
  `.claude/skills/`) explains the repo to people new to Azure.

## Develop

```sh
fmt              # format and lint
check            # nix flake check: lint, lock sync, docs, offline tofu validate
```

Editor: VS Code with the Nix IDE extension uses `.vscode/settings.json`
(nixd hints from this flake's nixpkgs, flake-parts and NixOS options;
alejandra on format). Start it from the devenv shell so `nixd` is on PATH.

License: MIT.
