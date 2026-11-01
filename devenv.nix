# This repo's additions to the org shell (org-pkgs/devenv).
{pkgs, ...}: let
  # Keep in step with flake-parts/terranix.nix.
  varlock = "bunx varlock@1.24.0";
in {
  # bun runs Varlock. The 1Password CLI is unfree and comes from the flake
  # instead: `nix run .#op`. No azure-cli: its nixpkgs build is broken
  # (python fabric marked broken); use Azure Cloud Shell or a local install.
  packages = [pkgs.bun];

  scripts = {
    plan = {
      exec = ''nix run .#sql-server.plan -- "$@"'';
      description = "Preview what OpenTofu would change in Azure";
    };
    apply = {
      exec = ''nix run .#sql-server.apply -- "$@"'';
      description = "Make the changes in Azure (asks for yes first)";
    };
    tofu = {
      exec = ''nix run .#tofu -- "$@"'';
      description = "Any other OpenTofu command, with credentials loaded (e.g. tofu output)";
    };
    env-check = {
      # op on PATH for the desktop app login, as in the tofu wrapper.
      exec = ''PATH="$(nix build --no-link --print-out-paths .#op)/bin:$PATH" ${varlock} load "$@"'';
      description = "Resolve .env.schema through 1Password and show the result, secrets redacted";
    };
  };
}
