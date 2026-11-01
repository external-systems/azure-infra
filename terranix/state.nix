# Where OpenTofu keeps its state, and how the state is protected.
#
# State lives in a private Azure Storage account (blob container), made
# once by scripts/azure-bootstrap.sh, outside OpenTofu (it has to exist
# before the first `tofu init`). It is encrypted client-side with a
# passphrase from 1Password before upload, because the Windows admin and
# SQL passwords have to be in it: Azure's VM API takes them as plain
# arguments. Blob versioning keeps old copies for 30 days.
{
  lib,
  config,
  ...
}: let
  cfg = config.azureInfra.state;
  inherit (lib) mkOption types;
in {
  options.azureInfra.state = {
    resourceGroupName = mkOption {
      type = types.str;
      default = "rg-azure-infra-state";
      description = "Resource group of the state storage account (made by scripts/azure-bootstrap.sh).";
    };
    containerName = mkOption {
      type = types.str;
      default = "tfstate";
      description = "Blob container that holds the state file.";
    };
    key = mkOption {
      type = types.str;
      default = "azure-infra/sql-server.tfstate";
      description = "Blob name of the state file inside the container.";
    };
  };

  config.terraform = {
    required_version = ">= 1.10";

    # storage_account_name is not here: the wrapper passes it to
    # `tofu init` from 1Password (TF_CLI_ARGS_init), so the public repo
    # never names it. Login: the service principal (ARM_* variables); the
    # backend looks up the account key with it. Locking: blob leases.
    backend.azurerm = {
      inherit (cfg) key;
      resource_group_name = cfg.resourceGroupName;
      container_name = cfg.containerName;
    };

    # https://opentofu.org/docs/language/state/encryption/
    # keys/method take a bare static reference: in JSON, "${...}" is a
    # template and tofu rejects it ("A single static variable reference").
    encryption = {
      key_provider.pbkdf2.passphrase.passphrase = "\${var.state_passphrase}";
      method.aes_gcm.default.keys = "key_provider.pbkdf2.passphrase";
      # enforced: tofu refuses to write unencrypted state or plans.
      state = {
        method = "method.aes_gcm.default";
        enforced = true;
      };
      plan = {
        method = "method.aes_gcm.default";
        enforced = true;
      };
    };
  };

  config.variable.state_passphrase = {
    type = "string";
    sensitive = true;
    description = "State encryption passphrase, read from 1Password by the wrapper.";
  };
}
