output "databricks_workspace_id" {
  description = "ID of the Databricks workspace"
  value       = module.databricks.databricks_workspace_id
}

output "databricks_workspace_url" {
  description = "URL of the Databricks workspace"
  value       = module.databricks.databricks_workspace_url
}

output "databricks_workspace_name" {
  description = "Name of the Databricks workspace"
  value       = module.databricks.databricks_workspace_name
}

output "databricks_managed_resource_group_name" {
  description = "Name of the managed resource group"
  value       = module.databricks.databricks_managed_resource_group_name
}

output "databricks_managed_resource_group_id" {
  description = "ID of the managed resource group"
  value       = module.databricks.databricks_managed_resource_group_id
}

output "interactive_cluster_ids" {
  description = "IDs of interactive clusters"
  value       = module.databricks.interactive_cluster_ids
}

output "job_cluster_ids" {
  description = "IDs of job clusters"
  value       = module.databricks.job_cluster_ids
}

output "job_ids" {
  description = "IDs of jobs"
  value       = module.databricks.job_ids
}

output "sql_warehouse_ids" {
  description = "IDs of SQL warehouses"
  value       = module.databricks.sql_warehouse_ids
}

output "private_endpoint_ids" {
  description = "IDs of private endpoints"
  value       = module.databricks.private_endpoint_ids
}