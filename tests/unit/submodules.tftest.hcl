mock_provider "azapi" {
  mock_resource "azapi_resource" {
    defaults = {
      id = "/subscriptions/00000000-0000-0000-0000-000000000000/resourceGroups/rg-health/providers/Microsoft.CloudHealth/healthmodels/hm-root-test/children/test"
    }
  }
}

mock_provider "modtm" {}
mock_provider "random" {}

run "authentication_setting_body" {
  command = apply

  module {
    source = "./modules/authentication-setting"
  }

  variables {
    enable_telemetry      = false
    name                  = "auth-shared"
    parent_id             = "/subscriptions/00000000-0000-0000-0000-000000000000/resourceGroups/rg-health/providers/Microsoft.CloudHealth/healthmodels/hm-root-test"
    display_name          = "Shared identity"
    managed_identity_name = "/subscriptions/00000000-0000-0000-0000-000000000000/resourceGroups/rg-health/providers/Microsoft.ManagedIdentity/userAssignedIdentities/id-health"
  }

  assert {
    condition     = length([azapi_resource.this]) == 1
    error_message = "The authentication-setting submodule must manage one primary resource."
  }

  assert {
    condition     = azapi_resource.this.body.properties.authenticationKind == "ManagedIdentity" && azapi_resource.this.body.properties.managedIdentityName == "/subscriptions/00000000-0000-0000-0000-000000000000/resourceGroups/rg-health/providers/Microsoft.ManagedIdentity/userAssignedIdentities/id-health"
    error_message = "The authentication-setting submodule must translate managed identity properties."
  }
}

run "entity_body" {
  command = apply

  module {
    source = "./modules/entity"
  }

  variables {
    enable_telemetry = false
    name             = "workload"
    parent_id        = "/subscriptions/00000000-0000-0000-0000-000000000000/resourceGroups/rg-health/providers/Microsoft.CloudHealth/healthmodels/hm-root-test"
    display_name     = "Workload"
    canvas_position = {
      x = 125
      y = 260
    }
    health_objective = 99.5
    impact           = "Limited"
    tags = {
      tier = "critical"
    }
    alerts = {
      degraded = {
        severity         = "Sev3"
        description      = "Workload degraded"
        action_group_ids = ["/subscriptions/00000000-0000-0000-0000-000000000000/resourceGroups/rg-health/providers/Microsoft.Insights/actionGroups/ag-health"]
      }
      unhealthy = {
        severity = "Sev1"
      }
    }
    signal_groups = {
      azure_resource = {
        authentication_setting = "auth-shared"
        azure_resource_id      = "/subscriptions/00000000-0000-0000-0000-000000000000/resourceGroups/rg-health/providers/Microsoft.Storage/storageAccounts/sthealth"
        resource_health = {
          enabled = "Enabled"
        }
        signals = [{
          name             = "availability"
          display_name     = "Availability"
          metric_namespace = "Microsoft.Storage/storageAccounts"
          metric_name      = "Availability"
          aggregation_type = "Average"
          data_unit        = "Percent"
          refresh_interval = "PT5M"
          time_grain       = "PT5M"
          evaluation_rules = {
            degraded_rule = {
              operator  = "LessThan"
              threshold = 99.9
            }
            unhealthy_rule = {
              operator  = "LessThan"
              threshold = 99
            }
          }
        }]
      }
      azure_monitor_workspace = {
        authentication_setting              = "auth-shared"
        azure_monitor_workspace_resource_id = "/subscriptions/00000000-0000-0000-0000-000000000000/resourceGroups/rg-health/providers/Microsoft.Monitor/accounts/amw-health"
        signals = [{
          name             = "restarts"
          query_text       = "sum(rate(restarts_total[5m])) or vector(0)"
          data_unit        = "Count"
          refresh_interval = "PT1M"
          time_grain       = "PT5M"
          evaluation_rules = {
            unhealthy_rule = {
              operator  = "GreaterThan"
              threshold = 8
            }
          }
        }]
      }
      azure_log_analytics = {
        authentication_setting              = "auth-shared"
        log_analytics_workspace_resource_id = "/subscriptions/00000000-0000-0000-0000-000000000000/resourceGroups/rg-health/providers/Microsoft.OperationalInsights/workspaces/law-health"
        signals = [{
          name              = "exceptions"
          query_text        = "AppExceptions | summarize ErrorCount=count()"
          value_column_name = "ErrorCount"
          data_unit         = "Count"
          refresh_interval  = "PT10M"
          time_grain        = "PT10M"
          evaluation_rules = {
            unhealthy_rule = {
              operator  = "GreaterThanOrEqual"
              threshold = 75
            }
          }
        }]
      }
      dependencies = {
        aggregation_type    = "MaxNotHealthy"
        unit                = "Absolute"
        degraded_threshold  = 2
        unhealthy_threshold = 4
        ignore_unknown      = false
      }
    }
  }

  assert {
    condition     = azapi_resource.this.body.properties.canvasPosition.x == 125 && azapi_resource.this.body.properties.healthObjective == 99.5 && azapi_resource.this.body.properties.impact == "Limited"
    error_message = "The entity submodule must translate common entity properties."
  }

  assert {
    condition     = azapi_resource.this.body.properties.signalGroups.azureResource.signals[0].metricName == "Availability" && azapi_resource.this.body.properties.signalGroups.azureResource.resourceHealth.enabled == "Enabled"
    error_message = "The entity submodule must translate Azure metric and Resource Health fields."
  }

  assert {
    condition     = azapi_resource.this.body.properties.signalGroups.azureMonitorWorkspace.signals[0].queryText == "sum(rate(restarts_total[5m])) or vector(0)" && azapi_resource.this.body.properties.signalGroups.azureLogAnalytics.signals[0].valueColumnName == "ErrorCount"
    error_message = "The entity submodule must translate PromQL and KQL fields."
  }

  assert {
    condition = (
      azapi_resource.this.body.properties.signalGroups.azureResource.signals[0].evaluationRules.degradedRule.threshold == 99.9 &&
      azapi_resource.this.body.properties.signalGroups.azureMonitorWorkspace.signals[0].evaluationRules.unhealthyRule.threshold == 8 &&
      azapi_resource.this.body.properties.signalGroups.azureLogAnalytics.signals[0].evaluationRules.unhealthyRule.threshold == 75
    )
    error_message = "The entity submodule must preserve different thresholds for all three monitoring signal kinds."
  }

  assert {
    condition     = azapi_resource.this.body.properties.signalGroups.dependencies.aggregationType == "MaxNotHealthy" && azapi_resource.this.body.properties.alerts.unhealthy.severity == "Sev1"
    error_message = "The entity submodule must translate dependency and alert configuration."
  }
}

run "embedded_health_model_body" {
  command = apply

  module {
    source = "./modules/entity"
  }

  variables {
    enable_telemetry = false
    name             = "child-model"
    parent_id        = "/subscriptions/00000000-0000-0000-0000-000000000000/resourceGroups/rg-health/providers/Microsoft.CloudHealth/healthmodels/hm-root-test"
    signal_groups = {
      embedded_health_model = {
        authentication_setting = "auth-system"
        resource_id            = "/subscriptions/00000000-0000-0000-0000-000000000000/resourceGroups/rg-health/providers/Microsoft.CloudHealth/healthmodels/hm-child"
      }
    }
  }

  assert {
    condition     = azapi_resource.this.body.properties.signalGroups.azureResource.azureResourceId == "/subscriptions/00000000-0000-0000-0000-000000000000/resourceGroups/rg-health/providers/Microsoft.CloudHealth/healthmodels/hm-child"
    error_message = "The embedded entity must use the child health model ID as its Azure resource ID."
  }

  assert {
    condition     = !can(azapi_resource.this.body.properties.signalGroups.azureResource.signals)
    error_message = "The embedded entity body must omit inline signals."
  }
}

run "signal_definition_body" {
  command = apply

  module {
    source = "./modules/signal-definition"
  }

  variables {
    enable_telemetry  = false
    name              = "kql-errors"
    parent_id         = "/subscriptions/00000000-0000-0000-0000-000000000000/resourceGroups/rg-health/providers/Microsoft.CloudHealth/healthmodels/hm-root-test"
    display_name      = "Application errors"
    signal_kind       = "LogAnalyticsQuery"
    data_unit         = "Count"
    refresh_interval  = "PT10M"
    query_text        = "AppExceptions | summarize ErrorCount=count()"
    time_grain        = "PT10M"
    value_column_name = "ErrorCount"
    evaluation_rules = {
      degraded_rule = {
        operator  = "GreaterThanOrEqual"
        threshold = 12
      }
      unhealthy_rule = {
        operator  = "GreaterThan"
        threshold = 75
      }
    }
  }

  assert {
    condition     = azapi_resource.this.body.properties.signalKind == "LogAnalyticsQuery" && azapi_resource.this.body.properties.queryText == "AppExceptions | summarize ErrorCount=count()" && azapi_resource.this.body.properties.valueColumnName == "ErrorCount"
    error_message = "The signal-definition submodule must translate the selected signal kind."
  }

  assert {
    condition     = azapi_resource.this.body.properties.evaluationRules.degradedRule.threshold == 12 && azapi_resource.this.body.properties.evaluationRules.unhealthyRule.threshold == 75
    error_message = "The signal-definition submodule must translate both evaluation rules."
  }
}

run "relationship_body" {
  command = apply

  module {
    source = "./modules/relationship"
  }

  variables {
    enable_telemetry   = false
    name               = "root-workload"
    parent_id          = "/subscriptions/00000000-0000-0000-0000-000000000000/resourceGroups/rg-health/providers/Microsoft.CloudHealth/healthmodels/hm-root-test"
    display_name       = "Root to workload"
    parent_entity_name = "hm-root-test"
    child_entity_name  = "workload"
    tags = {
      topology = "primary"
    }
  }

  assert {
    condition     = azapi_resource.this.body.properties.parentEntityName == "hm-root-test" && azapi_resource.this.body.properties.childEntityName == "workload" && azapi_resource.this.body.properties.tags.topology == "primary"
    error_message = "The relationship submodule must translate endpoints and tags."
  }
}

run "discovery_rule_body" {
  command = apply

  module {
    source = "./modules/discovery-rule"
  }

  variables {
    enable_telemetry           = false
    name                       = "discover-storage"
    parent_id                  = "/subscriptions/00000000-0000-0000-0000-000000000000/resourceGroups/rg-health/providers/Microsoft.CloudHealth/healthmodels/hm-root-test"
    display_name               = "Discover storage"
    authentication_setting     = "auth-shared"
    discover_relationships     = "Enabled"
    add_recommended_signals    = "Disabled"
    add_resource_health_signal = "Enabled"
    specification = {
      kind                 = "ResourceGraphQuery"
      resource_graph_query = "resources | where type =~ 'microsoft.storage/storageaccounts' | project id"
    }
  }

  assert {
    condition     = azapi_resource.this.body.properties.authenticationSetting == "auth-shared" && azapi_resource.this.body.properties.discoverRelationships == "Enabled" && azapi_resource.this.body.properties.addResourceHealthSignal == "Enabled"
    error_message = "The discovery-rule submodule must translate behavior fields."
  }

  assert {
    condition     = azapi_resource.this.body.properties.specification.kind == "ResourceGraphQuery" && azapi_resource.this.body.properties.specification.resourceGraphQuery == "resources | where type =~ 'microsoft.storage/storageaccounts' | project id"
    error_message = "The discovery-rule submodule must translate the Resource Graph specification."
  }
}
