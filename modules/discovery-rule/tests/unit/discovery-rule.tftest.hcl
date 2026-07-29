mock_provider "azapi" {}
mock_provider "modtm" {}
mock_provider "random" {}

variables {
  enable_telemetry        = false
  name                    = "discover-resources"
  parent_id               = "/subscriptions/00000000-0000-0000-0000-000000000000/resourceGroups/rg-health/providers/Microsoft.CloudHealth/healthmodels/hm-test"
  authentication_setting  = "auth-system"
  discover_relationships  = "Enabled"
  add_recommended_signals = "Disabled"
  specification = {
    kind                 = "ResourceGraphQuery"
    resource_graph_query = "resources | project id"
  }
}

run "resource_graph_discovery" {
  command = apply

  variables {
    resource_types = {
      cloudhealth_healthmodels_discoveryrules = "Microsoft.CloudHealth/healthModels/discoveryRules@2026-05-01-preview"
    }
  }

  assert {
    condition     = length([azapi_resource.this]) == 1 && azapi_resource.this.body.properties.specification.kind == "ResourceGraphQuery"
    error_message = "The submodule must create one Resource Graph discovery rule."
  }

  assert {
    condition     = azapi_resource.this.type == "Microsoft.CloudHealth/healthModels/discoveryRules@2026-05-01-preview"
    error_message = "The discovery-rule resource type override must use its deterministic ARM-derived key."
  }

  assert {
    condition     = contains(try(azapi_resource.this.retry.error_message_regex, []), "ScopeLocked")
    error_message = "The submodule must retry only the lock-removal propagation error by default."
  }
}

run "invalid_application_insights_id" {
  command = plan

  variables {
    specification = {
      kind                             = "ApplicationInsightsTopology"
      application_insights_resource_id = "/subscriptions/invalid"
    }
  }

  expect_failures = [
    var.specification,
  ]
}
