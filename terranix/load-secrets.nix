# Shell run by the tofu wrapper before every command (flake-parts/
# terranix.nix). Varlock resolves .env.schema (op:// references) through
# 1Password; the values only ever live in this process's environment.
{varlockVersion}: ''
  REPO_ROOT="$(git rev-parse --show-toplevel)"

  # NixOS (programs._1password): the desktop app only talks to the setgid
  # op wrapper, not the plain op from the Nix store. Prefer it when present.
  if [ -x /run/wrappers/bin/op ]; then
    export PATH="/run/wrappers/bin:$PATH"
  fi

  if ! varlock_env="$(bunx "varlock@${varlockVersion}" load --format shell --path "$REPO_ROOT/")"; then
    echo "error: Varlock could not load .env.schema from 1Password." >&2
    echo "Unlock the 1Password app (OP_ACCOUNT) or set OP_SERVICE_ACCOUNT_TOKEN in .env." >&2
    echo "Details, values redacted: env-check" >&2
    exit 1
  fi
  eval "$varlock_env"
  unset varlock_env

  # Backends take no variables: pass the private storage account name to
  # every `tofu init` instead of committing it.
  export TF_CLI_ARGS_init="-backend-config=storage_account_name=$TF_STATE_STORAGE_ACCOUNT"
''
