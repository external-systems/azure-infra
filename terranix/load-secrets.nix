# Shell run by the tofu wrapper before every command (flake-parts/
# terranix.nix). Varlock resolves .env.schema (op:// references) through
# 1Password; the values only ever live in this process's environment.
{varlockVersion}: ''
  REPO_ROOT="$(git rev-parse --show-toplevel)"

  if ! varlock_env="$(bunx "varlock@${varlockVersion}" load --format shell --path "$REPO_ROOT/")"; then
    echo "error: Varlock could not load .env.schema from 1Password." >&2
    echo "Unlock the 1Password app (OP_ACCOUNT) or set OP_SERVICE_ACCOUNT_TOKEN in .env." >&2
    echo "Details, values redacted: env-check" >&2
    exit 1
  fi
  eval "$varlock_env"
  unset varlock_env

  # The s3 backend takes no variables: pass the private bucket name to
  # every `tofu init` instead of committing it.
  export TF_CLI_ARGS_init="-backend-config=bucket=$TF_STATE_BUCKET"
''
