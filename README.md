# Databricks Module

This Terraform module creates an Azure Databricks workspace with enterprise-grade security features, VNet injection, cluster management, job orchestration, and SQL warehouses.

## Features

- **Databricks Workspace**: Premium SKU with managed resource group
- **VNet Injection**: Secure deployment within customer VNet
- **Customer-Managed Keys**: Encryption with Azure Key Vault
- **Private Endpoints**: Secure access without public IP
- **Interactive Clusters**: Configurable Spark clusters for development
- **Job Clusters**: Dedicated clusters for ETL workloads
- **Job Orchestration**: Multi-task jobs with dependencies
- **SQL Warehouses**: Serverless SQL analytics
- **Cluster Policies**: Governance and cost control
- **Azure Policy Integration**: Compliance and security policies
- **Comprehensive Monitoring**: Diagnostic settings and logging

## Usage

### Basic Example

```hcl
module "databricks" {
  source = "./modules/analytics/databricks"

  resource_group_name = "rg-databricks"
  location           = "westeurope"
  environment        = "prod"

  sku = "premium"

  tags = {
    Environment = "prod"
    Project     = "data-platform"
  }
}
```

### Complete Example with VNet Injection

```hcl
module "databricks" {
  source = "./modules/analytics/databricks"

  resource_group_name = "rg-databricks"
  location           = "westeurope"
  environment        = "prod"

  # VNet injection
  no_public_ip       = true
  virtual_network_id = azurerm_virtual_network.vnet.id
  private_subnet_name = "snet-databricks-private"
  public_subnet_name  = "snet-databricks-public"

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
    "data-eng-cluster" = {
      spark_version = "13.3.x-scala2.12"
      node_type_id  = "Standard_DS3_v2"
      num_workers   = 4
      autotermination_minutes = 120
      spark_conf = {
        "spark.databricks.delta.preview.enabled" = "true"
        "spark.sql.adaptive.enabled" = "true"
      }
      custom_tags = {
        "Team" = "Data Engineering"
        "CostCenter" = "DE-001"
      }
    }
  }

  # Job clusters
  job_clusters = {
    "etl-cluster" = {
      spark_version = "13.3.x-scala2.12"
      node_type_id  = "Standard_DS3_v2"
      num_workers   = 2
      autotermination_minutes = 60
    }
  }

  # ETL jobs
  jobs = {
    "daily-etl" = {
      job_cluster = {
        job_cluster_key = "etl-cluster"
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
              "source_path" = "/data/input"
            }
          }
        },
        {
          task_key = "transform"
          depends_on = [{ task_key = "extract" }]
          notebook_task = {
            notebook_path = "/Shared/ETL/transform"
          }
        },
        {
          task_key = "load"
          depends_on = [{ task_key = "transform" }]
          notebook_task = {
            notebook_path = "/Shared/ETL/load"
          }
        }
      ]
      schedule = {
        quartz_cron_expression = "0 0 6 * * ?"  # Daily at 6 AM
      }
      email_notifications = {
        on_failure = ["data-team@company.com"]
      }
      tags = {
        "team" = "data-engineering"
        "priority" = "high"
      }
    }
  }

  # SQL warehouses
  sql_warehouses = {
    "analytics-warehouse" = {
      cluster_size = "Medium"
      auto_stop_mins = 60
      tags = {
        "team" = "analytics"
      }
    }
  }

  # Private endpoints
  private_endpoints = {
    databricks = {
      subnet_id = azurerm_subnet.private.id
    }
  }

  tags = {
    Environment = "prod"
    Project     = "data-platform"
    Owner       = "Data Platform Team"
  }
}
```

## Requirements

| Name | Version |
|------|---------|
| terraform | >= 1.5.0 |
| azurerm | >= 3.80.0 |
| databricks | >= 1.0.0 |

## Providers

| Name | Version |
|------|---------|
| azurerm | >= 3.80.0 |
| databricks | >= 1.0.0 |

## Inputs

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|----------|
| databricks_workspace_name | Name of the Databricks workspace | `string` | `null` | no |
| naming_prefix | Prefix for Databricks naming | `string` | `"databricks"` | no |
| environment | Environment name (e.g., prod, dev, test) | `string` | n/a | yes |
| location | Azure region where resources will be created | `string` | n/a | yes |
| resource_group_name | Name of the resource group | `string` | n/a | yes |
| sku | Databricks workspace SKU | `string` | `"premium"` | no |
| managed_resource_group_name | Name of the managed resource group | `string` | `null` | no |
| no_public_ip | Disable public IP for Databricks workspace | `bool` | `true` | no |
| virtual_network_id | Virtual network ID for VNet injection | `string` | `null` | no |
| private_subnet_name | Private subnet name for Databricks | `string` | `null` | no |
| public_subnet_name | Public subnet name for Databricks | `string` | `null` | no |
| storage_account_name | Storage account name for Databricks | `string` | `null` | no |
| storage_account_sku_name | Storage account SKU name | `string` | `"Standard_GRS"` | no |
| customer_managed_key | Customer managed key configuration | `object` | `null` | no |
| infrastructure_encryption_enabled | Enable infrastructure encryption | `bool` | `true` | no |
| public_network_access_enabled | Enable public network access | `bool` | `false` | no |
| cluster_policies | Cluster policies configuration | `map` | `{}` | no |
| interactive_clusters | Interactive clusters configuration | `map` | `{}` | no |
| job_clusters | Job clusters configuration | `map` | `{}` | no |
| jobs | Jobs configuration | `map` | `{}` | no |
| notebooks | Notebooks configuration | `map` | `{}` | no |
| sql_warehouses | SQL warehouses configuration | `map` | `{}` | no |
| cluster_permissions | Cluster permissions configuration | `map` | `{}` | no |
| job_permissions | Job permissions configuration | `map` | `{}` | no |
| private_endpoints | Private endpoint configurations | `object` | `{}` | no |
| tags | Tags to apply to all resources | `map(string)` | `{}` | no |

## Outputs

| Name | Description |
|------|-------------|
| databricks_workspace_id | ID of the Databricks workspace |
| databricks_workspace_url | URL of the Databricks workspace |
| databricks_workspace_name | Name of the Databricks workspace |
| databricks_managed_resource_group_name | Name of the managed resource group |
| databricks_managed_resource_group_id | ID of the managed resource group |
| interactive_cluster_ids | IDs of interactive clusters |
| job_cluster_ids | IDs of job clusters |
| job_ids | IDs of jobs |
| sql_warehouse_ids | IDs of SQL warehouses |
| private_endpoint_ids | IDs of private endpoints |

## Security Features

- **VNet Injection**: Deploy Databricks within your virtual network
- **Private Endpoints**: Secure access without public exposure
- **Customer-Managed Keys**: Control encryption keys in Azure Key Vault
- **Infrastructure Encryption**: Double encryption for sensitive data
- **Network Security**: NSG associations and subnet delegations
- **Azure Policy**: Compliance and governance policies

## Monitoring and Logging

The module includes comprehensive diagnostic settings for:
- Databricks workspace activity
- Cluster operations
- Job executions
- SQL warehouse usage
- Security events and audit logs

## Testing

The module includes comprehensive Terratest coverage:

```bash
cd test
go test -v -run TestDatabricksModule
```

Tests cover:
- Basic workspace creation
- VNet injection configuration
- Job orchestration
- Private endpoint setup
- Naming convention validation
- SQL warehouse creation

## Contributing

1. Follow the established patterns for variable naming and resource configuration
2. Include comprehensive test coverage for new features
3. Update documentation for any new inputs or outputs
4. Ensure compliance with enterprise security requirements