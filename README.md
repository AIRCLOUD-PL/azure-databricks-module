<p align="center">
  <a href="https://aircloud.com.pl"><img src=".github/assets/banner.png" alt="AIRCLOUD: DevOps, cloud and AI engineering" width="100%"></a>
</p>

# azure-databricks-module

**Azure Databricks Terraform module — parameterised, azurerm 4.x, CI-validated.**

[![CI](https://github.com/AIRCLOUD-PL/azure-databricks-module/actions/workflows/ci.yml/badge.svg)](https://github.com/AIRCLOUD-PL/azure-databricks-module/actions/workflows/ci.yml)
[![License: MIT](https://img.shields.io/badge/License-MIT-blue.svg)](LICENSE)
[![Release](https://img.shields.io/github/v/release/AIRCLOUD-PL/azure-databricks-module?sort=semver)](https://github.com/AIRCLOUD-PL/azure-databricks-module/releases)

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

Pin the module to a release tag:

```hcl
module "databricks" {
  source = "git::https://github.com/AIRCLOUD-PL/azure-databricks-module.git?ref=v1.0.0"

  # required inputs
  environment         = "..."
  location            = "..."
  resource_group_name = "..."
}
```

All inputs and outputs are listed in the generated reference below ([Inputs](#inputs), [Outputs](#outputs)). Worked examples live in [`examples/`](examples/).

### Basic Example

```hcl
module "databricks" {
  source = "git::https://github.com/AIRCLOUD-PL/azure-databricks-module.git?ref=v1.0.0"

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
  source = "git::https://github.com/AIRCLOUD-PL/azure-databricks-module.git?ref=v1.0.0"

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

## Reference

<!-- BEGIN_TF_DOCS -->
## Requirements

| Name | Version |
|------|---------|
| <a name="requirement_terraform"></a> [terraform](#requirement\_terraform) | >= 1.5.0 |
| <a name="requirement_azurerm"></a> [azurerm](#requirement\_azurerm) | ~> 4.0 |
| <a name="requirement_databricks"></a> [databricks](#requirement\_databricks) | ~> 1.0 |

## Providers

| Name | Version |
|------|---------|
| <a name="provider_azurerm"></a> [azurerm](#provider\_azurerm) | 4.81.0 |
| <a name="provider_databricks.workspace"></a> [databricks.workspace](#provider\_databricks.workspace) | 1.145.0 |

## Modules

No modules.

## Resources

| Name | Type |
|------|------|
| [azurerm_databricks_workspace.main](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/databricks_workspace) | resource |
| [azurerm_private_endpoint.databricks](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/private_endpoint) | resource |
| [azurerm_resource_group_policy_assignment.databricks_diagnostic_settings](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/resource_group_policy_assignment) | resource |
| [azurerm_resource_group_policy_assignment.databricks_encryption](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/resource_group_policy_assignment) | resource |
| [azurerm_resource_group_policy_assignment.databricks_public_access](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/resource_group_policy_assignment) | resource |
| [azurerm_resource_group_policy_assignment.databricks_vnet_injection](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/resource_group_policy_assignment) | resource |
| [databricks_cluster.interactive_clusters](https://registry.terraform.io/providers/databricks/databricks/latest/docs/resources/cluster) | resource |
| [databricks_cluster.job_clusters](https://registry.terraform.io/providers/databricks/databricks/latest/docs/resources/cluster) | resource |
| [databricks_cluster_policy.policies](https://registry.terraform.io/providers/databricks/databricks/latest/docs/resources/cluster_policy) | resource |
| [databricks_job.jobs](https://registry.terraform.io/providers/databricks/databricks/latest/docs/resources/job) | resource |
| [databricks_notebook.notebooks](https://registry.terraform.io/providers/databricks/databricks/latest/docs/resources/notebook) | resource |
| [databricks_permissions.cluster_permissions](https://registry.terraform.io/providers/databricks/databricks/latest/docs/resources/permissions) | resource |
| [databricks_permissions.job_permissions](https://registry.terraform.io/providers/databricks/databricks/latest/docs/resources/permissions) | resource |
| [databricks_sql_endpoint.warehouses](https://registry.terraform.io/providers/databricks/databricks/latest/docs/resources/sql_endpoint) | resource |
| [azurerm_resource_group.main](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/data-sources/resource_group) | data source |

## Inputs

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|:--------:|
| <a name="input_cluster_permissions"></a> [cluster\_permissions](#input\_cluster\_permissions) | Cluster permissions configuration | <pre>map(object({<br/>    access_control = list(object({<br/>      user_name              = optional(string)<br/>      group_name             = optional(string)<br/>      service_principal_name = optional(string)<br/>      permission_level       = string<br/>    }))<br/>  }))</pre> | `{}` | no |
| <a name="input_cluster_policies"></a> [cluster\_policies](#input\_cluster\_policies) | Cluster policies configuration | <pre>map(object({<br/>    definition = map(any)<br/>  }))</pre> | `{}` | no |
| <a name="input_customer_managed_key"></a> [customer\_managed\_key](#input\_customer\_managed\_key) | Customer managed key configuration | <pre>object({<br/>    key_vault_key_id = string<br/>  })</pre> | `null` | no |
| <a name="input_databricks_workspace_name"></a> [databricks\_workspace\_name](#input\_databricks\_workspace\_name) | Name of the Databricks workspace. If null, will be auto-generated. | `string` | `null` | no |
| <a name="input_enable_policy_assignments"></a> [enable\_policy\_assignments](#input\_enable\_policy\_assignments) | Enable Azure Policy assignments for this Databricks workspace | `bool` | `true` | no |
| <a name="input_environment"></a> [environment](#input\_environment) | Environment name (e.g., prod, dev, test) | `string` | n/a | yes |
| <a name="input_infrastructure_encryption_enabled"></a> [infrastructure\_encryption\_enabled](#input\_infrastructure\_encryption\_enabled) | Enable infrastructure encryption | `bool` | `true` | no |
| <a name="input_interactive_clusters"></a> [interactive\_clusters](#input\_interactive\_clusters) | Interactive clusters configuration | <pre>map(object({<br/>    spark_version       = string<br/>    node_type_id        = string<br/>    driver_node_type_id = optional(string)<br/>    num_workers         = optional(number)<br/><br/>    autoscale = optional(object({<br/>      min_workers = number<br/>      max_workers = number<br/>    }))<br/><br/>    autotermination_minutes = optional(number, 60)<br/>    spark_conf              = optional(map(string), {})<br/>    custom_tags             = optional(map(string), {})<br/>    libraries = optional(list(object({<br/>      coordinates = string<br/>    })), [])<br/><br/>    policy_id = optional(string)<br/>  }))</pre> | `{}` | no |
| <a name="input_job_clusters"></a> [job\_clusters](#input\_job\_clusters) | Job clusters configuration | <pre>map(object({<br/>    spark_version       = string<br/>    node_type_id        = string<br/>    driver_node_type_id = optional(string)<br/>    num_workers         = optional(number)<br/><br/>    autoscale = optional(object({<br/>      min_workers = number<br/>      max_workers = number<br/>    }))<br/><br/>    autotermination_minutes = optional(number, 60)<br/>    spark_conf              = optional(map(string), {})<br/>    custom_tags             = optional(map(string), {})<br/>    libraries = optional(list(object({<br/>      coordinates = string<br/>    })), [])<br/><br/>    policy_id = optional(string)<br/>  }))</pre> | `{}` | no |
| <a name="input_job_permissions"></a> [job\_permissions](#input\_job\_permissions) | Job permissions configuration | <pre>map(object({<br/>    access_control = list(object({<br/>      user_name              = optional(string)<br/>      group_name             = optional(string)<br/>      service_principal_name = optional(string)<br/>      permission_level       = string<br/>    }))<br/>  }))</pre> | `{}` | no |
| <a name="input_jobs"></a> [jobs](#input\_jobs) | Jobs configuration | <pre>map(object({<br/>    job_cluster = optional(object({<br/>      job_cluster_key         = string<br/>      spark_version           = string<br/>      node_type_id            = string<br/>      driver_node_type_id     = optional(string)<br/>      num_workers             = optional(number)<br/>      autotermination_minutes = optional(number, 60)<br/><br/>      autoscale = optional(object({<br/>        min_workers = number<br/>        max_workers = number<br/>      }))<br/><br/>      spark_conf  = optional(map(string), {})<br/>      custom_tags = optional(map(string), {})<br/>    }))<br/><br/>    tasks = list(object({<br/>      task_key = string<br/><br/>      notebook_task = optional(object({<br/>        notebook_path   = string<br/>        base_parameters = optional(map(string), {})<br/>      }))<br/><br/>      python_task = optional(object({<br/>        python_file = string<br/>        parameters  = optional(list(string), [])<br/>      }))<br/><br/>      spark_jar_task = optional(object({<br/>        main_class_name = string<br/>        parameters      = optional(list(string), [])<br/>      }))<br/><br/>      sql_task = optional(object({<br/>        query_id     = string<br/>        warehouse_id = optional(string)<br/>      }))<br/><br/>      depends_on      = optional(list(string), [])<br/>      timeout_seconds = optional(number)<br/>    }))<br/><br/>    parameters = optional(list(object({<br/>      name  = string<br/>      value = string<br/>    })), [])<br/><br/>    schedule = optional(object({<br/>      quartz_cron_expression = string<br/>      timezone_id            = optional(string, "UTC")<br/>    }))<br/><br/>    email_notifications = optional(object({<br/>      on_start   = optional(list(string), [])<br/>      on_success = optional(list(string), [])<br/>      on_failure = optional(list(string), [])<br/>    }))<br/><br/>    webhook_notifications = optional(object({<br/>      on_start = optional(list(object({<br/>        id = string<br/>      })), [])<br/>      on_success = optional(list(object({<br/>        id = string<br/>      })), [])<br/>      on_failure = optional(list(object({<br/>        id = string<br/>      })), [])<br/>    }))<br/><br/>    timeout_seconds     = optional(number)<br/>    max_concurrent_runs = optional(number, 1)<br/>    environments = optional(list(object({<br/>      environment_key = string<br/>      spec = object({<br/>        dependencies = optional(list(string), [])<br/>      })<br/>    })), [])<br/><br/>    tags = optional(map(string), {})<br/>  }))</pre> | `{}` | no |
| <a name="input_location"></a> [location](#input\_location) | Azure region where resources will be created | `string` | n/a | yes |
| <a name="input_managed_resource_group_name"></a> [managed\_resource\_group\_name](#input\_managed\_resource\_group\_name) | Name of the managed resource group | `string` | `null` | no |
| <a name="input_naming_prefix"></a> [naming\_prefix](#input\_naming\_prefix) | Prefix for Databricks naming | `string` | `"databricks"` | no |
| <a name="input_no_public_ip"></a> [no\_public\_ip](#input\_no\_public\_ip) | Disable public IP for Databricks workspace | `bool` | `true` | no |
| <a name="input_notebooks"></a> [notebooks](#input\_notebooks) | Notebooks configuration | <pre>map(object({<br/>    path     = string<br/>    language = string<br/>    content  = string<br/>  }))</pre> | `{}` | no |
| <a name="input_private_endpoints"></a> [private\_endpoints](#input\_private\_endpoints) | Private endpoint configurations | <pre>object({<br/>    databricks = optional(object({<br/>      subnet_id            = string<br/>      private_dns_zone_ids = optional(list(string))<br/>    }))<br/>  })</pre> | `{}` | no |
| <a name="input_private_subnet_name"></a> [private\_subnet\_name](#input\_private\_subnet\_name) | Private subnet name for Databricks | `string` | `null` | no |
| <a name="input_private_subnet_network_security_group_association_id"></a> [private\_subnet\_network\_security\_group\_association\_id](#input\_private\_subnet\_network\_security\_group\_association\_id) | Private subnet NSG association ID | `string` | `null` | no |
| <a name="input_public_network_access_enabled"></a> [public\_network\_access\_enabled](#input\_public\_network\_access\_enabled) | Enable public network access | `bool` | `false` | no |
| <a name="input_public_subnet_name"></a> [public\_subnet\_name](#input\_public\_subnet\_name) | Public subnet name for Databricks | `string` | `null` | no |
| <a name="input_public_subnet_network_security_group_association_id"></a> [public\_subnet\_network\_security\_group\_association\_id](#input\_public\_subnet\_network\_security\_group\_association\_id) | Public subnet NSG association ID | `string` | `null` | no |
| <a name="input_resource_group_name"></a> [resource\_group\_name](#input\_resource\_group\_name) | Name of the resource group | `string` | n/a | yes |
| <a name="input_sku"></a> [sku](#input\_sku) | Databricks workspace SKU | `string` | `"premium"` | no |
| <a name="input_sql_warehouses"></a> [sql\_warehouses](#input\_sql\_warehouses) | SQL warehouses configuration | <pre>map(object({<br/>    cluster_size              = optional(string, "Small")<br/>    max_num_clusters          = optional(number, 1)<br/>    min_num_clusters          = optional(number, 1)<br/>    auto_stop_mins            = optional(number, 120)<br/>    spot_instance_policy      = optional(string, "COST_OPTIMIZED")<br/>    enable_serverless_compute = optional(bool, false)<br/>    tags                      = optional(map(string), {})<br/>  }))</pre> | `{}` | no |
| <a name="input_storage_account_name"></a> [storage\_account\_name](#input\_storage\_account\_name) | Storage account name for Databricks | `string` | `null` | no |
| <a name="input_storage_account_sku_name"></a> [storage\_account\_sku\_name](#input\_storage\_account\_sku\_name) | Storage account SKU name | `string` | `"Standard_GRS"` | no |
| <a name="input_tags"></a> [tags](#input\_tags) | Tags to apply to all resources | `map(string)` | `{}` | no |
| <a name="input_virtual_network_id"></a> [virtual\_network\_id](#input\_virtual\_network\_id) | Virtual network ID for VNet injection | `string` | `null` | no |

## Outputs

| Name | Description |
|------|-------------|
| <a name="output_cluster_permissions"></a> [cluster\_permissions](#output\_cluster\_permissions) | Cluster permissions |
| <a name="output_databricks_managed_resource_group_id"></a> [databricks\_managed\_resource\_group\_id](#output\_databricks\_managed\_resource\_group\_id) | Managed resource group ID |
| <a name="output_databricks_managed_resource_group_name"></a> [databricks\_managed\_resource\_group\_name](#output\_databricks\_managed\_resource\_group\_name) | Managed resource group name |
| <a name="output_databricks_storage_account_name"></a> [databricks\_storage\_account\_name](#output\_databricks\_storage\_account\_name) | Storage account name for the Databricks workspace (deprecated in 4.x) |
| <a name="output_databricks_workspace_id"></a> [databricks\_workspace\_id](#output\_databricks\_workspace\_id) | Databricks workspace ID |
| <a name="output_databricks_workspace_name"></a> [databricks\_workspace\_name](#output\_databricks\_workspace\_name) | Databricks workspace name |
| <a name="output_databricks_workspace_url"></a> [databricks\_workspace\_url](#output\_databricks\_workspace\_url) | Databricks workspace URL |
| <a name="output_interactive_clusters"></a> [interactive\_clusters](#output\_interactive\_clusters) | Interactive clusters |
| <a name="output_job_clusters"></a> [job\_clusters](#output\_job\_clusters) | Job clusters |
| <a name="output_job_permissions"></a> [job\_permissions](#output\_job\_permissions) | Job permissions |
| <a name="output_jobs"></a> [jobs](#output\_jobs) | Jobs |
| <a name="output_notebooks"></a> [notebooks](#output\_notebooks) | Notebooks |
| <a name="output_private_endpoint_databricks_id"></a> [private\_endpoint\_databricks\_id](#output\_private\_endpoint\_databricks\_id) | Databricks private endpoint ID |
| <a name="output_sql_warehouses"></a> [sql\_warehouses](#output\_sql\_warehouses) | SQL warehouses |
<!-- END_TF_DOCS -->

---

## Part of the AIRCLOUD Azure module catalog

Browse all modules with usage snippets in the [module catalog](https://aircloud-pl.github.io/) or on [github.com/AIRCLOUD-PL](https://github.com/AIRCLOUD-PL). Built and maintained by [AIRCLOUD](https://aircloud.com.pl): DevOps, cloud and AI engineering. Need a hand with Azure landing zones or platform engineering? See [aircloud.com.pl/consulting](https://aircloud.com.pl/consulting).
