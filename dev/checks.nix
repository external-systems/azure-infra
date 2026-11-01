# Offline gate for the OpenTofu configuration: provider schemas come from
# the Nix-built providers, so `tofu validate` needs no network and no
# credentials. Catches wrong argument names and types before a plan.
_: {
  perSystem = {
    config,
    pkgs,
    ...
  }: let
    sqlServer = config.terranix.terranixConfigurations.sql-server;
  in {
    checks.tofu-validate =
      pkgs.runCommand "tofu-validate" {
        nativeBuildInputs = [sqlServer.terraformWrapper.package];
      } ''
        export HOME="$TMPDIR"
        cp ${sqlServer.result.terraformConfiguration} config.tf.json
        tofu init -backend=false -input=false -no-color
        tofu validate -no-color
        touch "$out"
      '';
  };
}
