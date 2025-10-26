/**
 * Security configurations and policies for Databricks
 */

# Azure Policy - Require VNet injection
resource "azurerm_resource_group_policy_assignment" "databricks_vnet_injection" {
  count = var.enable_policy_assignments ? 1 : 0

  name                 = "${azurerm_databricks_workspace.main.name}-vnet-injection"
  resource_group_id    = data.azurerm_resource_group.main.id
  policy_definition_id = "/providers/Microsoft.Authorization/policyDefinitions/9d9d4e17-9506-4d59-9dfb-48dbb5f9b5c7"
  display_name         = "Azure Databricks Workspaces should be in a virtual network"
  description          = "Ensures Databricks workspaces use VNet injection for network isolation"

  parameters = jsonencode({
    effect = {
      value = "Audit"
    }
  })
}

# Azure Policy - Require encryption at rest
resource "azurerm_resource_group_policy_assignment" "databricks_encryption" {
  count = var.enable_policy_assignments ? 1 : 0

  name                 = "${azurerm_databricks_workspace.main.name}-encryption"
  resource_group_id    = data.azurerm_resource_group.main.id
  policy_definition_id = "/providers/Microsoft.Authorization/policyDefinitions/1e2e1b6a-5dd9-4e0f-9b1d-2b6b0a6c3e7a"
  display_name         = "Azure Databricks Workspaces should use customer-managed keys to encrypt data at rest"
  description          = "Ensures Databricks workspaces use customer-managed keys for encryption"

  parameters = jsonencode({
    effect = {
      value = "Audit"
    }
  })
}

# Azure Policy - Require public network access disabled
resource "azurerm_resource_group_policy_assignment" "databricks_public_access" {
  count = var.enable_policy_assignments ? 1 : 0

  name                 = "${azurerm_databricks_workspace.main.name}-public-access"
  resource_group_id    = data.azurerm_resource_group.main.id
  policy_definition_id = "/providers/Microsoft.Authorization/policyDefinitions/0e237389-9c99-4d48-8e5c-4c8b1f5b3e7a"
  display_name         = "Azure Databricks Workspaces should disable public network access"
  description          = "Ensures Databricks workspaces disable public network access"

  parameters = jsonencode({
    effect = {
      value = "Audit"
    }
  })
}

# Azure Policy - Require diagnostic settings
resource "azurerm_resource_group_policy_assignment" "databricks_diagnostic_settings" {
  count = var.enable_policy_assignments ? 1 : 0

  name                 = "${azurerm_databricks_workspace.main.name}-diagnostic-settings"
  resource_group_id    = data.azurerm_resource_group.main.id
  policy_definition_id = "/providers/Microsoft.Authorization/policyDefinitions/3834f2b6-1c4a-4e1e-8e8e-2b2b2b2b2b2b"
  display_name         = "Azure Databricks Workspaces should have diagnostic settings enabled"
  description          = "Ensures diagnostic settings are enabled for Databricks workspaces"

  parameters = jsonencode({
    effect = {
      value = "AuditIfNotExists"
    }
  })
}

# Data source for resource group
data "azurerm_resource_group" "main" {
  name = var.resource_group_name
}

# Variables for policies
variable "enable_policy_assignments" {
  description = "Enable Azure Policy assignments for this Databricks workspace"
  type        = bool
  default     = true
}