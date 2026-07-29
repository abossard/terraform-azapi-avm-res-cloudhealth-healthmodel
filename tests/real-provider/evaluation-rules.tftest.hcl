provider "azapi" {}
provider "modtm" {}
provider "random" {}

variables {
  enable_telemetry = false
  location         = "centralus"
  name             = "hm-evaluation-rules"
  parent_id        = "/subscriptions/00000000-0000-0000-0000-000000000000/resourceGroups/rg-health"
  managed_identities = {
    system_assigned = true
  }
  authentication_settings = {
    system = {
      name                  = "auth-system"
      managed_identity_name = "SystemAssigned"
    }
  }
}

run "invalid_inline_signal_operator" {
  command = plan

  variables {
    entities = {
      invalid = {
        name = "invalid-inline-operator"
        signal_groups = {
          azure_resource = {
            authentication_setting = "auth-system"
            azure_resource_id      = "/subscriptions/00000000-0000-0000-0000-000000000000/resourceGroups/rg-health/providers/Microsoft.Storage/storageAccounts/sthealth"
            signals = [{
              name             = "availability"
              metric_namespace = "Microsoft.Storage/storageAccounts"
              metric_name      = "Availability"
              aggregation_type = "Average"
              time_grain       = "PT5M"
              evaluation_rules = {
                unhealthy_rule = {
                  operator  = "Approximately"
                  threshold = 99
                }
              }
            }]
          }
        }
      }
    }
  }

  expect_failures = [
    azapi_resource.this,
  ]
}

run "degraded_dynamic_rule_requires_configuration" {
  command = plan

  variables {
    entities = {
      invalid = {
        name = "invalid-degraded-dynamic"
        signal_groups = {
          azure_resource = {
            authentication_setting = "auth-system"
            azure_resource_id      = "/subscriptions/00000000-0000-0000-0000-000000000000/resourceGroups/rg-health/providers/Microsoft.Storage/storageAccounts/sthealth"
            signals = [{
              name             = "availability"
              metric_namespace = "Microsoft.Storage/storageAccounts"
              metric_name      = "Availability"
              aggregation_type = "Average"
              time_grain       = "PT5M"
              evaluation_rules = {
                degraded_rule = {
                  operator = "Dynamic"
                }
                unhealthy_rule = {
                  operator  = "LessThan"
                  threshold = 99
                }
              }
            }]
          }
        }
      }
    }
  }

  expect_failures = [
    azapi_resource.this,
  ]
}
