mock_provider "azapi" {}
mock_provider "modtm" {}
mock_provider "random" {}

variables {
  enable_telemetry = false
  name             = "group-entity"
  parent_id        = "/subscriptions/00000000-0000-0000-0000-000000000000/resourceGroups/rg-health/providers/Microsoft.CloudHealth/healthmodels/hm-test"
  signal_groups = {
    dependencies = {
      aggregation_type = "WorstOf"
      ignore_unknown   = true
    }
  }
}

run "dependency_entity" {
  command = apply

  variables {
    resource_types = {
      cloudhealth_healthmodels_entities = "Microsoft.CloudHealth/healthModels/entities@2026-05-01-preview"
    }
  }

  assert {
    condition     = length([azapi_resource.this]) == 1 && azapi_resource.this.body.properties.signalGroups.dependencies.aggregationType == "WorstOf"
    error_message = "The submodule must create one dependency entity."
  }

  assert {
    condition     = azapi_resource.this.type == "Microsoft.CloudHealth/healthModels/entities@2026-05-01-preview"
    error_message = "The entity resource type override must use its deterministic ARM-derived key."
  }

  assert {
    condition     = contains(try(azapi_resource.this.retry.error_message_regex, []), "ScopeLocked")
    error_message = "The submodule must retry only the lock-removal propagation error by default."
  }
}

run "invalid_embedded_model_id" {
  command = plan

  variables {
    signal_groups = {
      embedded_health_model = {
        authentication_setting = "auth-system"
        resource_id            = "/subscriptions/invalid"
      }
    }
  }

  expect_failures = [
    var.signal_groups,
  ]
}

run "invalid_inline_signal_operator" {
  command = plan

  variables {
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

  expect_failures = [
    azapi_resource.this,
  ]
}

run "degraded_dynamic_inline_rule" {
  command = plan

  variables {
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

  expect_failures = [
    azapi_resource.this,
  ]
}
