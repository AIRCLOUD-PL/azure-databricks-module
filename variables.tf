variable "databricks_workspace_name" {
  description = "Name of the Databricks workspace. If null, will be auto-generated."
  type        = string
  default     = null
}

variable "naming_prefix" {
  description = "Prefix for Databricks naming"
  type        = string
  default     = "databricks"
}

variable "environment" {
  description = "Environment name (e.g., prod, dev, test)"
  type        = string
}

variable "location" {
  description = "Azure region where resources will be created"
  type        = string
}

variable "resource_group_name" {
  description = "Name of the resource group"
  type        = string
}

variable "sku" {
  description = "Databricks workspace SKU"
  type        = string
  default     = "premium"
  validation {
    condition     = contains(["standard", "premium"], var.sku)
    error_message = "SKU must be standard or premium."
  }
}

variable "managed_resource_group_name" {
  description = "Name of the managed resource group"
  type        = string
  default     = null
}

variable "no_public_ip" {
  description = "Disable public IP for Databricks workspace"
  type        = bool
  default     = true
}

variable "virtual_network_id" {
  description = "Virtual network ID for VNet injection"
  type        = string
  default     = null
}

variable "private_subnet_name" {
  description = "Private subnet name for Databricks"
  type        = string
  default     = null
}

variable "public_subnet_name" {
  description = "Public subnet name for Databricks"
  type        = string
  default     = null
}

variable "private_subnet_network_security_group_association_id" {
  description = "Private subnet NSG association ID"
  type        = string
  default     = null
}

variable "public_subnet_network_security_group_association_id" {
  description = "Public subnet NSG association ID"
  type        = string
  default     = null
}

variable "storage_account_name" {
  description = "Storage account name for Databricks"
  type        = string
  default     = null
}

variable "storage_account_sku_name" {
  description = "Storage account SKU name"
  type        = string
  default     = "Standard_GRS"
}

variable "customer_managed_key" {
  description = "Customer managed key configuration"
  type = object({
    key_vault_key_id = string
  })
  default = null
}

variable "infrastructure_encryption_enabled" {
  description = "Enable infrastructure encryption"
  type        = bool
  default     = true
}

variable "public_network_access_enabled" {
  description = "Enable public network access"
  type        = bool
  default     = false
}

variable "cluster_policies" {
  description = "Cluster policies configuration"
  type = map(object({
    definition = map(any)
  }))
  default = {}
}

variable "interactive_clusters" {
  description = "Interactive clusters configuration"
  type = map(object({
    spark_version       = string
    node_type_id        = string
    driver_node_type_id = optional(string)
    num_workers         = optional(number)

    autoscale = optional(object({
      min_workers = number
      max_workers = number
    }))

    autotermination_minutes = optional(number, 60)
    spark_conf              = optional(map(string), {})
    custom_tags             = optional(map(string), {})
    libraries = optional(list(object({
      coordinates = string
    })), [])

    policy_id = optional(string)
  }))
  default = {}
}

variable "job_clusters" {
  description = "Job clusters configuration"
  type = map(object({
    spark_version       = string
    node_type_id        = string
    driver_node_type_id = optional(string)
    num_workers         = optional(number)

    autoscale = optional(object({
      min_workers = number
      max_workers = number
    }))

    autotermination_minutes = optional(number, 60)
    spark_conf              = optional(map(string), {})
    custom_tags             = optional(map(string), {})
    libraries = optional(list(object({
      coordinates = string
    })), [])

    policy_id = optional(string)
  }))
  default = {}
}

variable "jobs" {
  description = "Jobs configuration"
  type = map(object({
    job_cluster = optional(object({
      job_cluster_key         = string
      spark_version           = string
      node_type_id            = string
      driver_node_type_id     = optional(string)
      num_workers             = optional(number)
      autotermination_minutes = optional(number, 60)

      autoscale = optional(object({
        min_workers = number
        max_workers = number
      }))

      spark_conf  = optional(map(string), {})
      custom_tags = optional(map(string), {})
    }))

    tasks = list(object({
      task_key = string

      notebook_task = optional(object({
        notebook_path   = string
        base_parameters = optional(map(string), {})
      }))

      python_task = optional(object({
        python_file = string
        parameters  = optional(list(string), [])
      }))

      spark_jar_task = optional(object({
        main_class_name = string
        parameters      = optional(list(string), [])
      }))

      sql_task = optional(object({
        query_id     = string
        warehouse_id = optional(string)
      }))

      depends_on      = optional(list(string), [])
      timeout_seconds = optional(number)
    }))

    parameters = optional(list(object({
      name  = string
      value = string
    })), [])

    schedule = optional(object({
      quartz_cron_expression = string
      timezone_id            = optional(string, "UTC")
    }))

    email_notifications = optional(object({
      on_start   = optional(list(string), [])
      on_success = optional(list(string), [])
      on_failure = optional(list(string), [])
    }))

    webhook_notifications = optional(object({
      on_start = optional(list(object({
        id = string
      })), [])
      on_success = optional(list(object({
        id = string
      })), [])
      on_failure = optional(list(object({
        id = string
      })), [])
    }))

    timeout_seconds     = optional(number)
    max_concurrent_runs = optional(number, 1)
    environments = optional(list(object({
      environment_key = string
      spec = object({
        dependencies = optional(list(string), [])
      })
    })), [])

    tags = optional(map(string), {})
  }))
  default = {}
}

variable "notebooks" {
  description = "Notebooks configuration"
  type = map(object({
    path     = string
    language = string
    content  = string
  }))
  default = {}
}

variable "sql_warehouses" {
  description = "SQL warehouses configuration"
  type = map(object({
    cluster_size              = optional(string, "Small")
    max_num_clusters          = optional(number, 1)
    min_num_clusters          = optional(number, 1)
    auto_stop_mins            = optional(number, 120)
    spot_instance_policy      = optional(string, "COST_OPTIMIZED")
    enable_serverless_compute = optional(bool, false)
    tags                      = optional(map(string), {})
  }))
  default = {}
}

variable "cluster_permissions" {
  description = "Cluster permissions configuration"
  type = map(object({
    access_control = list(object({
      user_name              = optional(string)
      group_name             = optional(string)
      service_principal_name = optional(string)
      permission_level       = string
    }))
  }))
  default = {}
}

variable "job_permissions" {
  description = "Job permissions configuration"
  type = map(object({
    access_control = list(object({
      user_name              = optional(string)
      group_name             = optional(string)
      service_principal_name = optional(string)
      permission_level       = string
    }))
  }))
  default = {}
}

variable "private_endpoints" {
  description = "Private endpoint configurations"
  type = object({
    databricks = optional(object({
      subnet_id            = string
      private_dns_zone_ids = optional(list(string))
    }))
  })
  default = {}
}

variable "tags" {
  description = "Tags to apply to all resources"
  type        = map(string)
  default     = {}
}