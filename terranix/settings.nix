# The values you are most likely to change. Public repo: never put a
# password, key, storage account name or IP address here. Every option is
# documented in sql-server.nix and state.nix; anything not set here uses
# its default.
{
  azureInfra.sqlServer = {
    # The state storage account name and the firewall allow-lists are
    # private and live in 1Password (item sql-server-settings), not here.
    name = "sql-web-01";
    location = "southcentralus";
    vm.size = "Standard_D4s_v5";

    sql = {
      connectivity = "PRIVATE";
      # Automatic database backups to a storage account, kept 30 days.
      backup.retentionDays = 30;
    };
  };
}
