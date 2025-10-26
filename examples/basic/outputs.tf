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