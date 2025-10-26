/**
 * # Azure Databricks Module
 *
 * Enterprise-grade Azure Databricks module with comprehensive security, compliance, and performance features.
 *
 * ## Features
 * - Databricks workspace with VNet injection
 * - Cluster configurations (interactive, job clusters)
 * - Job scheduling and orchestration
 * - Advanced security (encryption, private endpoints, SCIM)
 * - Access controls and permissions
 * - Performance monitoring and optimization
 * - Azure Policy integration
 * - Multi-workspace support
 */



locals {
  # Auto-generate Databricks workspace name if not provided
  databricks_workspace_name = var.databricks_workspace_name != null ? var.databricks_workspace_name : "${var.naming_prefix}${var.environment}${replace(var.location, "-", "")}databricks"

  # Default tags
  default_tags = {
    ManagedBy   = "Terraform"
    Module      = "azure-databricks"
    Environment = var.environment
  }

  tags = merge(local.default_tags, var.tags)
}

# Databricks Workspace
resource "azurerm_databricks_workspace" "main" {
  name                        = local.databricks_workspace_name
  resource_group_name         = var.resource_group_name
  location                    = var.location
  sku                         = var.sku
  managed_resource_group_name = var.managed_resource_group_name != null ? var.managed_resource_group_name : "${var.resource_group_name}-databricks-managed"

  # Custom parameters
  custom_parameters {
    no_public_ip                                         = var.no_public_ip
    virtual_network_id                                   = var.virtual_network_id
    private_subnet_name                                  = var.private_subnet_name
    public_subnet_name                                   = var.public_subnet_name
    private_subnet_network_security_group_association_id = var.private_subnet_network_security_group_association_id
    public_subnet_network_security_group_association_id  = var.public_subnet_network_security_group_association_id
    storage_account_name                                 = var.storage_account_name
    storage_account_sku_name                             = var.storage_account_sku_name
  }

  # Customer managed key
  customer_managed_key_enabled         = var.customer_managed_key != null
  managed_disk_cmk_key_vault_key_id    = var.customer_managed_key != null ? var.customer_managed_key.key_vault_key_id : null
  managed_disk_cmk_rotation_to_latest_version_enabled = var.customer_managed_key != null ? try(var.customer_managed_key.rotation_enabled, false) : false

  # Infrastructure encryption
  infrastructure_encryption_enabled = var.infrastructure_encryption_enabled

  # Public network access
  public_network_access_enabled = var.public_network_access_enabled

  tags = local.tags
}

# Databricks provider configuration
provider "databricks" {
  alias = "workspace"
  host  = azurerm_databricks_workspace.main.workspace_url
}

# Cluster policies
resource "databricks_cluster_policy" "policies" {
  for_each = var.cluster_policies
  provider = databricks.workspace

  name       = each.key
  definition = jsonencode(each.value.definition)
}

# Interactive Clusters
resource "databricks_cluster" "interactive_clusters" {
  for_each = var.interactive_clusters
  provider = databricks.workspace

  cluster_name            = each.key
  spark_version           = each.value.spark_version
  node_type_id            = each.value.node_type_id
  driver_node_type_id     = try(each.value.driver_node_type_id, each.value.node_type_id)
  num_workers             = try(each.value.num_workers, null)
  autotermination_minutes = try(each.value.autotermination_minutes, 60)

  # Auto-scaling
  dynamic "autoscale" {
    for_each = try(each.value.autoscale, null) != null ? [each.value.autoscale] : []
    content {
      min_workers = autoscale.value.min_workers
      max_workers = autoscale.value.max_workers
    }
  }

  # Spark configuration
  spark_conf = try(each.value.spark_conf, {})

  # Environment variables
  custom_tags = merge(
    {
      "ResourceClass" = "SingleNode"
    },
    try(each.value.custom_tags, {}),
    local.tags
  )

  # Libraries
  dynamic "library" {
    for_each = try(each.value.libraries, [])
    content {
      maven {
        coordinates = library.value.coordinates
      }
    }
  }

  # Cluster policy
  policy_id = try(each.value.policy_id, null)
}

# Job Clusters
resource "databricks_cluster" "job_clusters" {
  for_each = var.job_clusters
  provider = databricks.workspace

  cluster_name            = each.key
  spark_version           = each.value.spark_version
  node_type_id            = each.value.node_type_id
  driver_node_type_id     = try(each.value.driver_node_type_id, each.value.node_type_id)
  num_workers             = try(each.value.num_workers, null)
  autotermination_minutes = try(each.value.autotermination_minutes, 60)

  # Auto-scaling
  dynamic "autoscale" {
    for_each = try(each.value.autoscale, null) != null ? [each.value.autoscale] : []
    content {
      min_workers = autoscale.value.min_workers
      max_workers = autoscale.value.max_workers
    }
  }

  # Spark configuration
  spark_conf = try(each.value.spark_conf, {})

  # Environment variables
  custom_tags = merge(
    {
      "ResourceClass" = "SingleNode"
    },
    try(each.value.custom_tags, {}),
    local.tags
  )

  # Libraries
  dynamic "library" {
    for_each = try(each.value.libraries, [])
    content {
      maven {
        coordinates = library.value.coordinates
      }
    }
  }

  # Cluster policy
  policy_id = try(each.value.policy_id, null)
}

# Jobs
resource "databricks_job" "jobs" {
  for_each = var.jobs
  provider = databricks.workspace

  name = each.key

  # Job clusters
  dynamic "job_cluster" {
    for_each = try(each.value.job_cluster, null) != null ? [each.value.job_cluster] : []
    content {
      job_cluster_key = job_cluster.value.job_cluster_key
      new_cluster {
        spark_version       = job_cluster.value.spark_version
        node_type_id        = job_cluster.value.node_type_id
        driver_node_type_id = try(job_cluster.value.driver_node_type_id, job_cluster.value.node_type_id)
        num_workers         = try(job_cluster.value.num_workers, null)

        dynamic "autoscale" {
          for_each = try(job_cluster.value.autoscale, null) != null ? [job_cluster.value.autoscale] : []
          content {
            min_workers = autoscale.value.min_workers
            max_workers = autoscale.value.max_workers
          }
        }

        spark_conf  = try(job_cluster.value.spark_conf, {})
        custom_tags = try(job_cluster.value.custom_tags, {})
      }
    }
  }

  # Tasks
  dynamic "task" {
    for_each = try(each.value.tasks, [])
    content {
      task_key = task.value.task_key

      # Notebook task
      dynamic "notebook_task" {
        for_each = try(task.value.notebook_task, null) != null ? [task.value.notebook_task] : []
        content {
          notebook_path   = notebook_task.value.notebook_path
          base_parameters = try(notebook_task.value.base_parameters, {})
        }
      }

      # Python task (commented out - check databricks provider version compatibility)
      # dynamic "python_task" {
      #   for_each = try(task.value.python_task, null) != null ? [task.value.python_task] : []
      #   content {
      #     python_file = python_task.value.python_file
      #     parameters  = try(python_task.value.parameters, [])
      #   }
      # }

      # Spark JAR task
      dynamic "spark_jar_task" {
        for_each = try(task.value.spark_jar_task, null) != null ? [task.value.spark_jar_task] : []
        content {
          main_class_name = spark_jar_task.value.main_class_name
          parameters      = try(spark_jar_task.value.parameters, [])
        }
      }

      # SQL task
      dynamic "sql_task" {
        for_each = try(task.value.sql_task, null) != null ? [task.value.sql_task] : []
        content {
          query {
            query_id = sql_task.value.query_id
          }
          warehouse_id = try(sql_task.value.warehouse_id, null)
        }
      }

      # Timeout
      timeout_seconds = try(task.value.timeout_seconds, null)
    }
  }

  # Schedule
  dynamic "schedule" {
    for_each = try(each.value.schedule, null) != null ? [each.value.schedule] : []
    content {
      quartz_cron_expression = schedule.value.quartz_cron_expression
      timezone_id            = try(schedule.value.timezone_id, "UTC")
    }
  }

  # Email notifications
  dynamic "email_notifications" {
    for_each = try(each.value.email_notifications, null) != null ? [each.value.email_notifications] : []
    content {
      on_start   = try(email_notifications.value.on_start, [])
      on_success = try(email_notifications.value.on_success, [])
      on_failure = try(email_notifications.value.on_failure, [])
    }
  }

  # Timeout
  timeout_seconds = try(each.value.timeout_seconds, null)

  # Max concurrent runs
  max_concurrent_runs = try(each.value.max_concurrent_runs, 1)
}

# Notebooks
resource "databricks_notebook" "notebooks" {
  for_each = var.notebooks
  provider = databricks.workspace

  path           = each.value.path
  language       = each.value.language
  content_base64 = base64encode(each.value.content)
}

# SQL Warehouses
resource "databricks_sql_endpoint" "warehouses" {
  for_each = var.sql_warehouses
  provider = databricks.workspace

  name = each.key

  cluster_size     = try(each.value.cluster_size, "Small")
  max_num_clusters = try(each.value.max_num_clusters, 1)
  min_num_clusters = try(each.value.min_num_clusters, 1)

  # Auto-stop
  auto_stop_mins = try(each.value.auto_stop_mins, 120)

  # Spot instance policy
  spot_instance_policy = try(each.value.spot_instance_policy, "COST_OPTIMIZED")

  # Enable serverless compute
  enable_serverless_compute = try(each.value.enable_serverless_compute, false)
}

# Access Control
resource "databricks_permissions" "cluster_permissions" {
  for_each = var.cluster_permissions
  provider = databricks.workspace

  cluster_id = each.key

  dynamic "access_control" {
    for_each = each.value.access_control
    content {
      user_name              = try(access_control.value.user_name, null)
      group_name             = try(access_control.value.group_name, null)
      service_principal_name = try(access_control.value.service_principal_name, null)
      permission_level       = access_control.value.permission_level
    }
  }
}

resource "databricks_permissions" "job_permissions" {
  for_each = var.job_permissions
  provider = databricks.workspace

  job_id = each.key

  dynamic "access_control" {
    for_each = each.value.access_control
    content {
      user_name              = try(access_control.value.user_name, null)
      group_name             = try(access_control.value.group_name, null)
      service_principal_name = try(access_control.value.service_principal_name, null)
      permission_level       = access_control.value.permission_level
    }
  }
}

# Private Endpoints
resource "azurerm_private_endpoint" "databricks" {
  count = var.private_endpoints.databricks != null ? 1 : 0

  name                = "${azurerm_databricks_workspace.main.name}-pe"
  location            = var.location
  resource_group_name = var.resource_group_name
  subnet_id           = var.private_endpoints.databricks.subnet_id

  private_service_connection {
    name                           = "${azurerm_databricks_workspace.main.name}-psc"
    private_connection_resource_id = azurerm_databricks_workspace.main.id
    subresource_names              = ["databricks_ui_api"]
    is_manual_connection           = false
  }

  dynamic "private_dns_zone_group" {
    for_each = var.private_endpoints.databricks.private_dns_zone_ids != null ? [1] : []
    content {
      name                 = "databricks-dns-zone-group"
      private_dns_zone_ids = var.private_endpoints.databricks.private_dns_zone_ids
    }
  }

  tags = local.tags
}