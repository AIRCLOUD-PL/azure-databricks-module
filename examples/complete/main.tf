terraform {
  required_version = ">= 1.5.0"
  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = ">= 3.80.0"
    }
    databricks = {
      source  = "databricks/databricks"
      version = ">= 1.0.0"
    }
  }
}

provider "azurerm" {
  features {}
}

data "azurerm_client_config" "current" {}

resource "azurerm_resource_group" "example" {
  name     = var.resource_group_name
  location = var.location
}

# Virtual Network for VNet injection
resource "azurerm_virtual_network" "example" {
  name                = "vnet-databricks-example"
  address_space       = ["10.0.0.0/16"]
  location            = azurerm_resource_group.example.location
  resource_group_name = azurerm_resource_group.example.name
}

resource "azurerm_subnet" "private" {
  name                 = "snet-databricks-private"
  resource_group_name  = azurerm_resource_group.example.name
  virtual_network_name = azurerm_virtual_network.example.name
  address_prefixes     = ["10.0.1.0/24"]

  delegation {
    name = "databricks-private"
    service_delegation {
      name = "Microsoft.Databricks/workspaces"
      actions = [
        "Microsoft.Network/virtualNetworks/subnets/join/action",
        "Microsoft.Network/virtualNetworks/subnets/prepareNetworkPolicies/action",
        "Microsoft.Network/virtualNetworks/subnets/unprepareNetworkPolicies/action",
      ]
    }
  }
}

resource "azurerm_subnet" "public" {
  name                 = "snet-databricks-public"
  resource_group_name  = azurerm_resource_group.example.name
  virtual_network_name = azurerm_virtual_network.example.name
  address_prefixes     = ["10.0.2.0/24"]

  delegation {
    name = "databricks-public"
    service_delegation {
      name = "Microsoft.Databricks/workspaces"
      actions = [
        "Microsoft.Network/virtualNetworks/subnets/join/action",
        "Microsoft.Network/virtualNetworks/subnets/prepareNetworkPolicies/action",
        "Microsoft.Network/virtualNetworks/subnets/unprepareNetworkPolicies/action",
      ]
    }
  }
}

# Network Security Groups
resource "azurerm_network_security_group" "private" {
  name                = "nsg-databricks-private"
  location            = azurerm_resource_group.example.location
  resource_group_name = azurerm_resource_group.example.name
}

resource "azurerm_network_security_group" "public" {
  name                = "nsg-databricks-public"
  location            = azurerm_resource_group.example.location
  resource_group_name = azurerm_resource_group.example.name
}

resource "azurerm_subnet_network_security_group_association" "private" {
  subnet_id                 = azurerm_subnet.private.id
  network_security_group_id = azurerm_network_security_group.private.id
}

resource "azurerm_subnet_network_security_group_association" "public" {
  subnet_id                 = azurerm_subnet.public.id
  network_security_group_id = azurerm_network_security_group.public.id
}

# Storage Account for DBFS
resource "azurerm_storage_account" "dbfs" {
  name                     = "stgdatabricksdbfs"
  resource_group_name      = azurerm_resource_group.example.name
  location                 = azurerm_resource_group.example.location
  account_tier             = "Standard"
  account_replication_type = "LRS"
  is_hns_enabled           = true
}

# Key Vault for customer-managed keys
resource "azurerm_key_vault" "example" {
  name                        = "kv-databricks-example"
  location                    = azurerm_resource_group.example.location
  resource_group_name         = azurerm_resource_group.example.name
  enabled_for_disk_encryption = true
  tenant_id                   = data.azurerm_client_config.current.tenant_id
  soft_delete_retention_days  = 7
  purge_protection_enabled    = false

  sku_name = "standard"

  access_policy {
    tenant_id = data.azurerm_client_config.current.tenant_id
    object_id = data.azurerm_client_config.current.object_id

    key_permissions = [
      "Get", "Create", "Delete", "List", "Update", "Import", "Backup", "Restore",
      "Decrypt", "Encrypt", "UnwrapKey", "WrapKey", "Verify", "Sign"
    ]

    secret_permissions = [
      "Get", "Set", "Delete", "List", "Backup", "Restore"
    ]
  }
}

resource "azurerm_key_vault_key" "databricks" {
  name         = "key-databricks-workspace"
  key_vault_id = azurerm_key_vault.example.id
  key_type     = "RSA"
  key_size     = 2048

  key_opts = [
    "decrypt", "encrypt", "sign", "unwrapKey", "verify", "wrapKey",
  ]
}

module "databricks" {
  source = "../../"

  resource_group_name = azurerm_resource_group.example.name
  location            = azurerm_resource_group.example.location
  environment         = var.environment

  # VNet injection
  no_public_ip        = true
  virtual_network_id  = azurerm_virtual_network.example.id
  private_subnet_name = azurerm_subnet.private.name
  public_subnet_name  = azurerm_subnet.public.name

  # Customer-managed key
  customer_managed_key = {
    key_vault_key_id = azurerm_key_vault_key.databricks.id
  }

  # Storage account for DBFS
  storage_account_name = azurerm_storage_account.dbfs.name

  # Security settings
  public_network_access_enabled = false

  # Interactive clusters
  interactive_clusters = {
    "interactive-cluster" = {
      spark_version           = "13.3.x-scala2.12"
      node_type_id            = "Standard_DS3_v2"
      num_workers             = 2
      autotermination_minutes = 60
      spark_conf = {
        "spark.databricks.delta.preview.enabled" = "true"
      }
      custom_tags = {
        "Team" = "Data Engineering"
      }
    }
  }

  # Job clusters
  job_clusters = {
    "job-cluster" = {
      spark_version           = "13.3.x-scala2.12"
      node_type_id            = "Standard_DS3_v2"
      num_workers             = 2
      autotermination_minutes = 30
      spark_conf = {
        "spark.sql.adaptive.enabled" = "true"
      }
    }
  }

  # Jobs
  jobs = {
    "sample-etl-job" = {
      name = "Sample ETL Job"
      job_cluster = {
        job_cluster_key = "job-cluster"
        spark_version   = "13.3.x-scala2.12"
        node_type_id    = "Standard_DS3_v2"
        num_workers     = 2
      }
      tasks = [
        {
          task_key = "extract"
          notebook_task = {
            notebook_path = "/Shared/ETL/extract"
            base_parameters = {
              "input_path" = "/data/input"
            }
          }
        },
        {
          task_key = "transform"
          depends_on = [
            {
              task_key = "extract"
            }
          ]
          notebook_task = {
            notebook_path = "/Shared/ETL/transform"
          }
        },
        {
          task_key = "load"
          depends_on = [
            {
              task_key = "transform"
            }
          ]
          notebook_task = {
            notebook_path = "/Shared/ETL/load"
          }
        }
      ]
      parameters = {
        "environment" = "prod"
      }
      tags = {
        "team" = "data-engineering"
      }
    }
  }

  # SQL Warehouses
  sql_warehouses = {
    "warehouse1" = {
      name           = "SQL Warehouse 1"
      cluster_size   = "Medium"
      auto_stop_mins = 60
      tags = {
        "team" = "analytics"
      }
    }
  }

  # Private endpoints
  private_endpoints = {
    "databricks" = {
      subnet_id = azurerm_subnet.private.id
    }
  }

  # Tags
  tags = {
    Environment = var.environment
    Project     = "databricks-complete-example"
    Owner       = "Data Platform Team"
  }
}