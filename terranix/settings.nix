# The values you are most likely to change. Public repo: never put a
# password, key, bucket name or IP address here. Every option is documented
# in sql-server.nix and state.nix; anything not set here uses its default.
{
  azureInfra = {
    # The bucket name and the firewall allow-lists are private and live in
    # 1Password (item sql-server-settings), not here: this repo is public.
    state.location = "fsn1";

    sqlServer = {
      name = "sql-web-01";
      location = "eastus2";
      vm.size = "Standard_D4s_v5";

      sql.connectivity = "PRIVATE";
    };
  };
}
