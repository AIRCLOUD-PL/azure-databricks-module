output "databricks_workspace_id" {
  description = "Databricks workspace ID"
  value       = azurerm_databricks_workspace.main.id
}

output "databricks_workspace_name" {
  description = "Databricks workspace name"
  value       = azurerm_databricks_workspace.main.name
}

output "databricks_workspace_url" {
  description = "Databricks workspace URL"
  value       = azurerm_databricks_workspace.main.workspace_url
}

output "databricks_managed_resource_group_id" {
  description = "Managed resource group ID"
  value       = azurerm_databricks_workspace.main.managed_resource_group_id
}

output "databricks_managed_resource_group_name" {
  description = "Managed resource group name"
  value       = azurerm_databricks_workspace.main.managed_resource_group_name
}

output "databricks_storage_account_name" {
  description = "Storage account name for the Databricks workspace (deprecated in 4.x)"
  value       = null
}

output "interactive_clusters" {
  description = "Interactive clusters"
  value       = databricks_cluster.interactive_clusters
}

output "job_clusters" {
  description = "Job clusters"
  value       = databricks_cluster.job_clusters
}

output "jobs" {
  description = "Jobs"
  value       = databricks_job.jobs
}

output "notebooks" {
  description = "Notebooks"
  value       = databricks_notebook.notebooks
}

output "sql_warehouses" {
  description = "SQL warehouses"
  value       = databricks_sql_endpoint.warehouses
}

output "cluster_permissions" {
  description = "Cluster permissions"
  value       = databricks_permissions.cluster_permissions
}

output "job_permissions" {
  description = "Job permissions"
  value       = databricks_permissions.job_permissions
}

output "private_endpoint_databricks_id" {
  description = "Databricks private endpoint ID"
  value       = var.private_endpoints.databricks != null ? azurerm_private_endpoint.databricks[0].id : null
}