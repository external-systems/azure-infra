# Where OpenTofu keeps its state, and how the state is protected.
#
# State lives in a private Hetzner Object Storage bucket (S3 API). It is
# encrypted client-side with a passphrase from 1Password before upload,
# because the Windows admin and SQL passwords have to be in it: Azure's
# VM API takes them as plain arguments.
{
  lib,
  config,
  ...
}: let
  cfg = config.azureInfra.state;
  inherit (lib) mkOption types;
in {
  options.azureInfra.state = {
    location = mkOption {
      type = types.enum ["fsn1" "nbg1" "hel1"];
      default = "fsn1";
      description = "Hetzner Object Storage location the bucket was created in.";
    };
    key = mkOption {
      type = types.str;
      default = "azure-infra/sql-server.tfstate";
      description = "Object key of the state file inside the bucket.";
    };
  };

  config.terraform = {
    required_version = ">= 1.10";

    # bucket is not here: the wrapper passes it to `tofu init` from
    # 1Password (TF_CLI_ARGS_init), so the public repo never names it.
    backend.s3 = {
      inherit (cfg) key;
      region = cfg.location;
      endpoints.s3 = "https://${cfg.location}.your-objectstorage.com";
      use_path_style = true;
      # S3-native locking (conditional writes); no DynamoDB needed.
      use_lockfile = true;
      # Hetzner is not AWS: skip the AWS-only checks.
      skip_credentials_validation = true;
      skip_metadata_api_check = true;
      skip_region_validation = true;
      skip_requesting_account_id = true;
      skip_s3_checksum = true;
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
