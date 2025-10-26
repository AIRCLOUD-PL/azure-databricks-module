package test

import (
	"testing"

	"github.com/gruntwork-io/terratest/modules/terraform"
	"github.com/stretchr/testify/assert"
)

func TestDatabricksModuleBasic(t *testing.T) {
	t.Parallel()

	terraformOptions := terraform.WithDefaultRetryableErrors(t, &terraform.Options{
		TerraformDir: "../examples/basic",

		Vars: map[string]interface{}{
			"resource_group_name": "rg-test-databricks-basic",
			"location":           "westeurope",
			"environment":        "test",
		},

		PlanOnly: true,
	})

	defer terraform.Destroy(t, terraformOptions)

	planStruct := terraform.InitAndPlan(t, terraformOptions)

	terraform.RequirePlannedValuesMapKeyExists(t, planStruct, "azurerm_databricks_workspace.main")
}

func TestDatabricksModuleWithVNetInjection(t *testing.T) {
	t.Parallel()

	terraformOptions := terraform.WithDefaultRetryableErrors(t, &terraform.Options{
		TerraformDir: "../examples/complete",

		Vars: map[string]interface{}{
			"resource_group_name": "rg-test-databricks-vnet",
			"location":           "westeurope",
			"environment":        "test",
			"no_public_ip":       true,
			"virtual_network_id": "/subscriptions/sub/resourceGroups/rg/providers/Microsoft.Network/virtualNetworks/vnet",
			"private_subnet_name": "snet-databricks-private",
			"public_subnet_name":  "snet-databricks-public",
			"interactive_clusters": map[string]interface{}{
				"interactive-cluster": map[string]interface{}{
					"spark_version": "10.4.x-scala2.12",
					"node_type_id":  "Standard_DS3_v2",
					"num_workers":   2,
				},
			},
			"job_clusters": map[string]interface{}{
				"job-cluster": map[string]interface{}{
					"spark_version": "10.4.x-scala2.12",
					"node_type_id":  "Standard_DS3_v2",
					"num_workers":   2,
				},
			},
		},

		PlanOnly: true,
	})

	defer terraform.Destroy(t, terraformOptions)

	planStruct := terraform.InitAndPlan(t, terraformOptions)

	terraform.RequirePlannedValuesMapKeyExists(t, planStruct, "azurerm_databricks_workspace.main")
	terraform.RequirePlannedValuesMapKeyExists(t, planStruct, "databricks_cluster.interactive_clusters")
	terraform.RequirePlannedValuesMapKeyExists(t, planStruct, "databricks_cluster.job_clusters")
}

func TestDatabricksModuleWithJobs(t *testing.T) {
	t.Parallel()

	terraformOptions := terraform.WithDefaultRetryableErrors(t, &terraform.Options{
		TerraformDir: "../examples/complete",

		Vars: map[string]interface{}{
			"resource_group_name": "rg-test-databricks-jobs",
			"location":           "westeurope",
			"environment":        "test",
			"jobs": map[string]interface{}{
				"sample-job": map[string]interface{}{
					"job_cluster": map[string]interface{}{
						"job_cluster_key": "job-cluster",
						"spark_version":   "10.4.x-scala2.12",
						"node_type_id":    "Standard_DS3_v2",
						"num_workers":     2,
					},
					"tasks": []map[string]interface{}{
						{
							"task_key": "task1",
							"notebook_task": map[string]interface{}{
								"notebook_path": "/Shared/sample-notebook",
							},
						},
					},
				},
			},
		},

		PlanOnly: true,
	})

	defer terraform.Destroy(t, terraformOptions)

	planStruct := terraform.InitAndPlan(t, terraformOptions)

	terraform.RequirePlannedValuesMapKeyExists(t, planStruct, "databricks_job.jobs")
}

func TestDatabricksModuleWithPrivateEndpoint(t *testing.T) {
	t.Parallel()

	terraformOptions := terraform.WithDefaultRetryableErrors(t, &terraform.Options{
		TerraformDir: "../examples/complete",

		Vars: map[string]interface{}{
			"resource_group_name": "rg-test-databricks-pe",
			"location":           "westeurope",
			"environment":        "test",
			"public_network_access_enabled": false,
			"private_endpoints": map[string]interface{}{
				"databricks": map[string]interface{}{
					"subnet_id": "/subscriptions/sub/resourceGroups/rg/providers/Microsoft.Network/virtualNetworks/vnet/subnets/subnet",
				},
			},
		},

		PlanOnly: true,
	})

	defer terraform.Destroy(t, terraformOptions)

	planStruct := terraform.InitAndPlan(t, terraformOptions)

	terraform.RequirePlannedValuesMapKeyExists(t, planStruct, "azurerm_private_endpoint.databricks")
}

func TestDatabricksModuleNamingConvention(t *testing.T) {
	t.Parallel()

	terraformOptions := terraform.WithDefaultRetryableErrors(t, &terraform.Options{
		TerraformDir: "../examples/basic",

		Vars: map[string]interface{}{
			"resource_group_name": "rg-test-databricks-naming",
			"location":           "westeurope",
			"environment":        "prod",
			"naming_prefix":      "databricksprod",
		},

		PlanOnly: true,
	})

	defer terraform.Destroy(t, terraformOptions)

	planStruct := terraform.InitAndPlan(t, terraformOptions)

	resourceChanges := terraform.GetResourceChanges(t, planStruct)

	for _, change := range resourceChanges {
		if change.Type == "azurerm_databricks_workspace" && change.Change.After != null {
			afterMap := change.Change.After.(map[string]interface{})
			if name, ok := afterMap["name"]; ok {
				databricksName := name.(string)
				assert.Contains(t, databricksName, "prod", "Databricks workspace name should contain environment")
			}
		}
	}
}

func TestDatabricksModuleWithSQLWarehouses(t *testing.T) {
	t.Parallel()

	terraformOptions := terraform.WithDefaultRetryableErrors(t, &terraform.Options{
		TerraformDir: "../examples/complete",

		Vars: map[string]interface{}{
			"resource_group_name": "rg-test-databricks-sql",
			"location":           "westeurope",
			"environment":        "test",
			"sql_warehouses": map[string]interface{}{
				"warehouse1": map[string]interface{}{
					"cluster_size": "Medium",
					"auto_stop_mins": 60,
				},
			},
		},

		PlanOnly: true,
	})

	defer terraform.Destroy(t, terraformOptions)

	planStruct := terraform.InitAndPlan(t, terraformOptions)

	terraform.RequirePlannedValuesMapKeyExists(t, planStruct, "databricks_sql_endpoint.warehouses")
}