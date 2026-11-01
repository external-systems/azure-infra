# OpenTofu configuration `sql-server`, generated from the terranix modules
# in ../terranix. Commands (run from the repo root):
#   nix run .#sql-server.plan     preview changes
#   nix run .#sql-server.apply    apply (asks for "yes")
#   nix run .#tofu -- <args>      raw tofu with the same credentials
#   nix run .#op -- <args>        1Password CLI (first-time setup)
{inputs, ...}: {
  imports = [inputs.terranix.flakeModule];

  perSystem = {
    config,
    lib,
    pkgs,
    system,
    ...
  }: let
    # Terranix modules. settings.nix holds the values people change.
    modules = [
      ../terranix/settings.nix
      ../terranix/state.nix
      ../terranix/sql-server.nix
    ];

    sqlServer = config.terranix.terranixConfigurations.sql-server;

    # The 1Password CLI is unfree; allow just that package, not the whole set.
    op =
      (import inputs.nixpkgs {
        inherit system;
        config.allowUnfreePredicate = p: lib.getName p == "1password-cli";
      })._1password-cli;
  in {
    # The org dev shell is devenv (devenv.yaml); no flake devShells.
    terranix = {
      exportDevShells = false;

      terranixConfigurations.sql-server = {
        inherit modules;
        # Relative to the current directory: always run from the repo root.
        workdir = ".tofu/sql-server";
        terraformWrapper = {
          package = pkgs.opentofu.withPlugins (p: [
            p.hashicorp_azurerm
            p."1password_onepassword"
          ]);
          # bun runs Varlock; Varlock's 1Password plugin calls op for the
          # desktop app login.
          extraRuntimeInputs = [pkgs.bun pkgs.git op];
          # Every credential is read from 1Password at run time (Varlock,
          # .env.schema), so none is ever written to the Nix store or repo.
          prefixText = import ../terranix/load-secrets.nix {
            varlockVersion = "1.24.0";
          };
        };
      };
    };

    packages = {
      tofu = sqlServer.result.terraformWrapper;
      # `nix run .#op -- <args>`: 1Password CLI for the one-time setup.
      inherit op;
    };
  };
}
