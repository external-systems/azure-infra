# The SQL Server 2019 Web edition VM and everything it needs: resource
# group, network, firewall (NSG), public IP, managed data disks, the SQL
# IaaS Agent registration, and the two generated passwords in 1Password.
# Values are set in settings.nix; every option below has a default.
{
  lib,
  config,
  ...
}: let
  cfg = config.azureInfra.sqlServer;
  inherit (lib) mkOption types mkIf mkMerge;

  # "${type.name.attr}": a reference OpenTofu resolves at plan/apply time.
  ref = path: "\${${path}}";
  rgName = ref "azurerm_resource_group.sql.name";
  location = ref "azurerm_resource_group.sql.location";
  tags = cfg.tags // {managed-by = "azure-infra";};

  publicIp = ref "azurerm_public_ip.sql.ip_address";
  privateIp = ref "azurerm_network_interface.sql.private_ip_address";

  # A password 1Password generates when the item is first created.
  passwordRecipe = {
    length = cfg.passwordLength;
    digits = true;
    symbols = true;
  };

  diskSubmodule = types.submodule {
    options = {
      lun = mkOption {
        type = types.ints.between 0 63;
        description = "Slot (LUN) the disk is attached at. Unique per VM; never change it on a live disk.";
      };
      sizeGb = mkOption {
        type = types.ints.positive;
        description = "Disk size in GiB. Can grow later, never shrink.";
      };
      storageAccountType = mkOption {
        type = types.enum ["Premium_LRS" "StandardSSD_LRS" "Standard_LRS" "Premium_ZRS" "StandardSSD_ZRS"];
        default = "Premium_LRS";
        description = "Disk performance tier. Premium SSD is Microsoft's minimum recommendation for SQL Server.";
      };
      caching = mkOption {
        type = types.enum ["None" "ReadOnly" "ReadWrite"];
        description = "Host caching. Microsoft recommends ReadOnly for data files and None for logs.";
      };
      path = mkOption {
        type = types.str;
        description = "Folder SQL Server uses on this disk by default.";
      };
    };
  };

  # One inbound allow rule, created only when `enabledExpr` is true at plan
  # time. The source CIDRs come from a variable (1Password), never the repo.
  inboundRule = {
    name,
    priority,
    port,
    sourcesVar,
    enabledExpr,
  }: {
    count = "\${${enabledExpr} ? 1 : 0}";
    inherit name priority;
    resource_group_name = rgName;
    network_security_group_name = ref "azurerm_network_security_group.sql.name";
    direction = "Inbound";
    access = "Allow";
    protocol = "Tcp";
    source_port_range = "*";
    destination_port_range = toString port;
    source_address_prefixes = ref "local.${sourcesVar}";
    destination_address_prefix = "*";
  };
in {
  options.azureInfra.sqlServer = {
    name = mkOption {
      type = types.strMatching "[a-z0-9-]{1,15}";
      default = "sql-web-01";
      description = "Base name of every resource and the Windows computer name (15 characters at most). Changing it replaces the VM.";
    };
    location = mkOption {
      type = types.str;
      default = "southcentralus";
      description = "Azure region (`az account list-locations -o table`). Changing it replaces everything.";
    };
    resourceGroupName = mkOption {
      type = types.str;
      default = "rg-${cfg.name}";
      defaultText = lib.literalExpression ''"rg-''${name}"'';
      description = "Resource group (folder) that holds every resource.";
    };
    tags = mkOption {
      type = types.attrsOf types.str;
      default = {workload = "sql-server-web";};
      description = "Tags on every resource, for cost reports and search.";
    };

    network = {
      addressSpace = mkOption {
        type = types.listOf types.str;
        default = ["10.50.0.0/16"];
        description = "Private address range of the virtual network.";
      };
      subnetPrefix = mkOption {
        type = types.str;
        default = "10.50.1.0/24";
        description = "Private address range of the VM's subnet, inside addressSpace.";
      };
    };

    vm = {
      size = mkOption {
        type = types.str;
        default = "Standard_D4s_v5";
        description = "VM size (CPU and memory). Web edition uses at most 16 cores and 64 GB of buffer pool. Changing it reboots the VM.";
      };
      adminUsername = mkOption {
        type = types.str;
        default = "azureadmin";
        description = "Windows administrator login. Changing it replaces the VM.";
      };
      timezone = mkOption {
        type = types.str;
        default = "UTC";
        description = "Windows time zone ID, e.g. \"Central Standard Time\".";
      };
      osDiskSizeGb = mkOption {
        type = types.ints.positive;
        default = 127;
        description = "C: drive size in GiB.";
      };
      image = mkOption {
        type = types.attrsOf types.str;
        default = {
          publisher = "MicrosoftSQLServer";
          offer = "sql2019-ws2019";
          sku = "web";
          version = "latest";
        };
        description = "Marketplace image: SQL Server 2019 Web on Windows Server 2019, SQL license billed per hour. Changing it replaces the VM.";
      };
    };

    disks = mkOption {
      type = types.attrsOf diskSubmodule;
      default = {
        data = {
          lun = 0;
          sizeGb = 256;
          caching = "ReadOnly";
          path = "F:\\data";
        };
        log = {
          lun = 1;
          sizeGb = 128;
          caching = "None";
          path = "G:\\log";
        };
      };
      description = "Managed data disks. `data` and `log` are required: SQL Server puts its data and log files on them.";
    };

    sql = {
      connectivity = mkOption {
        type = types.enum ["LOCAL" "PRIVATE" "PUBLIC"];
        default = "PRIVATE";
        description = "Who SQL Server listens to: LOCAL (the VM only), PRIVATE (the virtual network), PUBLIC (the internet, filtered by sql_source_cidrs in 1Password).";
      };
      port = mkOption {
        type = types.port;
        default = 1433;
        description = "SQL Server TCP port.";
      };
      loginUsername = mkOption {
        type = types.str;
        default = "sqladmin";
        description = "SQL authentication login the SQL IaaS extension creates (sysadmin). Not 'sa'.";
      };
      tempDbPath = mkOption {
        type = types.str;
        default = "D:\\tempDb";
        description = "tempdb folder, on the VM's fast local temporary disk (D:).";
      };
      autoPatching = {
        enabled = mkOption {
          type = types.bool;
          default = true;
          description = "Let the SQL IaaS extension install Windows and SQL updates in a weekly window.";
        };
        dayOfWeek = mkOption {
          type = types.enum ["Everyday" "Monday" "Tuesday" "Wednesday" "Thursday" "Friday" "Saturday" "Sunday"];
          default = "Sunday";
          description = "Day of the patch window.";
        };
        startHour = mkOption {
          type = types.ints.between 0 23;
          default = 2;
          description = "Start hour of the patch window, in the VM's time zone.";
        };
        durationMinutes = mkOption {
          type = types.ints.between 30 180;
          default = 60;
          description = "Length of the patch window.";
        };
      };
    };

    protectData = mkOption {
      type = types.bool;
      default = true;
      description = "Refuse any plan that would delete the VM or its data disks (lifecycle.prevent_destroy).";
    };

    passwordLength = mkOption {
      type = types.ints.between 16 64;
      default = 32;
      description = "Length of the passwords 1Password generates for the Windows admin and the SQL login.";
    };
  };

  config = mkMerge [
    {
      assertions = [
        {
          assertion = cfg.disks ? data && cfg.disks ? log;
          message = "azureInfra.sqlServer.disks needs a `data` and a `log` disk.";
        }
      ];
    }

    # --- Providers --- #
    {
      terraform.required_providers = {
        azurerm = {
          source = "hashicorp/azurerm";
          version = "~> 5.0";
        };
        onepassword = {
          source = "1Password/onepassword";
          version = "~> 3.0";
        };
      };

      # Both read their credentials from the environment, which the wrapper
      # fills from 1Password (Varlock, .env.schema):
      #   azurerm     ARM_SUBSCRIPTION_ID, ARM_TENANT_ID, ARM_CLIENT_ID, ARM_CLIENT_SECRET
      #   onepassword OP_SERVICE_ACCOUNT_TOKEN, or OP_ACCOUNT for the desktop app
      provider = {
        azurerm = {
          features = {};
          # The SQL IaaS Agent registration needs this resource provider.
          resource_providers_to_register = ["Microsoft.SqlVirtualMachine"];
        };
        onepassword = {};
      };

      variable = {
        onepassword_vault = {
          type = "string";
          description = "1Password vault for the generated passwords; set by the wrapper.";
        };
        # Private (public repo): read from 1Password item sql-server-settings.
        rdp_source_cidrs = {
          type = "string";
          default = "";
          sensitive = true;
          description = "Comma-separated public CIDRs allowed to RDP (port 3389). Empty: no RDP from the internet.";
        };
        sql_source_cidrs = {
          type = "string";
          default = "";
          sensitive = true;
          description = "Comma-separated public CIDRs allowed to reach SQL Server. Used only with sql.connectivity = \"PUBLIC\".";
        };
      };

      # "a, b," -> ["a", "b"]
      locals = {
        rdp_source_cidrs = "\${[for c in split(\",\", var.rdp_source_cidrs) : trimspace(c) if trimspace(c) != \"\"]}";
        sql_source_cidrs = "\${[for c in split(\",\", var.sql_source_cidrs) : trimspace(c) if trimspace(c) != \"\"]}";
      };

      data.onepassword_vault.sql.name = ref "var.onepassword_vault";
    }

    # --- Passwords, generated and stored by 1Password --- #
    {
      resource.onepassword_item = {
        vm_admin = {
          vault = ref "data.onepassword_vault.sql.uuid";
          title = "${cfg.name} Windows admin";
          category = "login";
          username = cfg.vm.adminUsername;
          url = "rdp://${publicIp}";
          tags = ["azure-infra" cfg.name];
          password_recipe = passwordRecipe;
        };

        sql_login = {
          vault = ref "data.onepassword_vault.sql.uuid";
          title = "${cfg.name} SQL login";
          category = "database";
          type = "mssql";
          hostname =
            if cfg.sql.connectivity == "PUBLIC"
            then publicIp
            else privateIp;
          port = toString cfg.sql.port;
          username = cfg.sql.loginUsername;
          tags = ["azure-infra" cfg.name];
          password_recipe = passwordRecipe;
        };
      };
    }

    # --- Network --- #
    {
      resource = {
        azurerm_resource_group.sql = {
          inherit (cfg) location;
          inherit tags;
          name = cfg.resourceGroupName;
        };

        azurerm_virtual_network.sql = {
          inherit location tags;
          name = "vnet-${cfg.name}";
          resource_group_name = rgName;
          address_space = cfg.network.addressSpace;
        };

        azurerm_subnet.sql = {
          name = "snet-${cfg.name}";
          resource_group_name = rgName;
          virtual_network_name = ref "azurerm_virtual_network.sql.name";
          address_prefixes = [cfg.network.subnetPrefix];
        };

        # Firewall. Azure denies all inbound internet traffic unless a rule
        # below allows it.
        azurerm_network_security_group.sql = {
          inherit location tags;
          name = "nsg-${cfg.name}";
          resource_group_name = rgName;
        };

        azurerm_network_security_rule = {
          allow_rdp = inboundRule {
            name = "allow-rdp";
            priority = 100;
            port = 3389;
            sourcesVar = "rdp_source_cidrs";
            # nonsensitive: the CIDRs are secret (CI logs are public), whether
            # there are any is not, and count may not depend on secrets.
            enabledExpr = "nonsensitive(length(local.rdp_source_cidrs) > 0)";
          };
          allow_sql = inboundRule {
            name = "allow-sql";
            priority = 110;
            inherit (cfg.sql) port;
            sourcesVar = "sql_source_cidrs";
            enabledExpr =
              if cfg.sql.connectivity == "PUBLIC"
              then "nonsensitive(length(local.sql_source_cidrs) > 0)"
              else "false";
          };
        };

        azurerm_subnet_network_security_group_association.sql = {
          subnet_id = ref "azurerm_subnet.sql.id";
          network_security_group_id = ref "azurerm_network_security_group.sql.id";
        };

        azurerm_public_ip.sql = {
          inherit location tags;
          name = "pip-${cfg.name}";
          resource_group_name = rgName;
          allocation_method = "Static";
          sku = "Standard";
        };

        azurerm_network_interface.sql = {
          inherit location tags;
          name = "nic-${cfg.name}";
          resource_group_name = rgName;
          ip_configuration = {
            name = "primary";
            subnet_id = ref "azurerm_subnet.sql.id";
            private_ip_address_allocation = "Dynamic";
            public_ip_address_id = ref "azurerm_public_ip.sql.id";
          };
        };
      };
    }

    # --- Virtual machine and disks --- #
    {
      resource = {
        azurerm_windows_virtual_machine.sql = {
          inherit location tags;
          name = "vm-${cfg.name}";
          computer_name = cfg.name;
          resource_group_name = rgName;
          inherit (cfg.vm) size timezone;
          admin_username = cfg.vm.adminUsername;
          admin_password = ref "onepassword_item.vm_admin.password";
          network_interface_ids = [(ref "azurerm_network_interface.sql.id")];
          patch_mode = "AutomaticByOS";
          automatic_updates_enabled = true;
          provision_vm_agent = true;

          os_disk = {
            name = "osdisk-${cfg.name}";
            caching = "ReadWrite";
            storage_account_type = "Premium_LRS";
            disk_size_gb = cfg.vm.osDiskSizeGb;
          };

          source_image_reference = cfg.vm.image;

          identity.type = "SystemAssigned";
          # Managed boot diagnostics: screenshot and serial log in the portal.
          boot_diagnostics = {};

          lifecycle = {
            # Azure can only set admin_password by replacing the VM. Change
            # the password on the server, then update 1Password by hand.
            ignore_changes = ["admin_password"];
            prevent_destroy = cfg.protectData;
          };
        };

        azurerm_managed_disk =
          lib.mapAttrs (n: d: {
            inherit location tags;
            name = "disk-${cfg.name}-${n}";
            resource_group_name = rgName;
            storage_account_type = d.storageAccountType;
            create_option = "Empty";
            disk_size_gb = d.sizeGb;
            lifecycle.prevent_destroy = cfg.protectData;
          })
          cfg.disks;

        azurerm_virtual_machine_data_disk_attachment =
          lib.mapAttrs (n: d: {
            inherit (d) lun caching;
            managed_disk_id = ref "azurerm_managed_disk.${n}.id";
            virtual_machine_id = ref "azurerm_windows_virtual_machine.sql.id";
          })
          cfg.disks;
      };
    }

    # --- SQL Server IaaS Agent: license, storage layout, patching --- #
    {
      resource.azurerm_mssql_virtual_machine.sql = {
        inherit tags;
        virtual_machine_id = ref "azurerm_windows_virtual_machine.sql.id";
        sql_license_type = "PAYG";
        sql_connectivity_type = cfg.sql.connectivity;
        sql_connectivity_port = cfg.sql.port;
        sql_connectivity_update_username = cfg.sql.loginUsername;
        sql_connectivity_update_password = ref "onepassword_item.sql_login.password";

        # Formats the data disks and points SQL Server at them.
        storage_configuration = {
          disk_type = "NEW";
          storage_workload_type = "OLTP";
          data_settings = {
            default_file_path = cfg.disks.data.path;
            luns = [cfg.disks.data.lun];
          };
          log_settings = {
            default_file_path = cfg.disks.log.path;
            luns = [cfg.disks.log.lun];
          };
          temp_db_settings = {
            default_file_path = cfg.sql.tempDbPath;
            luns = [];
          };
        };

        auto_patching = mkIf cfg.sql.autoPatching.enabled {
          day_of_week = cfg.sql.autoPatching.dayOfWeek;
          maintenance_window_starting_hour = cfg.sql.autoPatching.startHour;
          maintenance_window_duration_in_minutes = cfg.sql.autoPatching.durationMinutes;
        };

        # The disks must be attached before the extension formats them.
        depends_on = map (n: "azurerm_virtual_machine_data_disk_attachment.${n}") (lib.attrNames cfg.disks);

        # Same as admin_password: rotate on the server, then in 1Password.
        lifecycle.ignore_changes = ["sql_connectivity_update_password"];
      };
    }

    # --- Outputs (read with `tofu output -raw public_ip`) --- #
    {
      output = {
        # sensitive: CI logs of this public repo are public.
        public_ip = {
          value = publicIp;
          sensitive = true;
        };
        private_ip = {
          value = privateIp;
          sensitive = true;
        };
        vm_id.value = ref "azurerm_windows_virtual_machine.sql.id";
        onepassword_vm_admin_item.value = ref "onepassword_item.vm_admin.uuid";
        onepassword_sql_login_item.value = ref "onepassword_item.sql_login.uuid";
      };
    }
  ];
}
