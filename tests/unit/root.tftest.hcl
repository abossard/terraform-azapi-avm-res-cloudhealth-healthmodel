mock_provider "azapi" {
  mock_resource "azapi_resource" {
    defaults = {
      id = "/subscriptions/00000000-0000-0000-0000-000000000000/resourceGroups/rg-health/providers/Microsoft.CloudHealth/healthmodels/hm-root-test"
      output = {
        identity = {
          principalId = "11111111-1111-1111-1111-111111111111"
          tenantId    = "22222222-2222-2222-2222-222222222222"
        }
      }
    }
  }

  mock_data "azapi_client_config" {
    defaults = {
      subscription_id = "00000000-0000-0000-0000-000000000000"
      tenant_id       = "22222222-2222-2222-2222-222222222222"
    }
  }

  mock_data "azapi_resource_list" {
    defaults = {
      output = {
        results = []
      }
    }
  }
}

mock_provider "modtm" {}
mock_provider "random" {}

variables {
  enable_telemetry = false
  location         = "eastus2"
  name             = "hm-root-test"
  parent_id        = "/subscriptions/00000000-0000-0000-0000-000000000000/resourceGroups/rg-health"
}

run "root_resource" {
  command = apply

  variables {
    managed_identities = {
      system_assigned = true
      user_assigned_resource_ids = [
        "/subscriptions/00000000-0000-0000-0000-000000000000/resourceGroups/rg-health/providers/Microsoft.ManagedIdentity/userAssignedIdentities/id-health"
      ]
    }
    tags = {
      environment = "test"
      workload    = "health"
    }
  }

  assert {
    condition     = length([azapi_resource.this]) == 1
    error_message = "The module must manage exactly one health model primary resource."
  }

  assert {
    condition     = azapi_resource.this.type == "Microsoft.CloudHealth/healthmodels@2026-05-01-preview"
    error_message = "The health model must use the tested preview resource type."
  }

  assert {
    condition     = azapi_resource.this.name == "hm-root-test" && azapi_resource.this.parent_id == var.parent_id && azapi_resource.this.location == "eastus2"
    error_message = "The primary resource must preserve name, parent, and location."
  }

  assert {
    condition     = azapi_resource.this.tags.environment == "test" && azapi_resource.this.tags.workload == "health"
    error_message = "The primary resource must preserve caller tags."
  }

  assert {
    condition     = one(azapi_resource.this.identity).type == "SystemAssigned, UserAssigned" && contains(one(azapi_resource.this.identity).identity_ids, "/subscriptions/00000000-0000-0000-0000-000000000000/resourceGroups/rg-health/providers/Microsoft.ManagedIdentity/userAssignedIdentities/id-health")
    error_message = "The primary resource must preserve requested managed identities."
  }

  assert {
    condition     = azapi_resource.this.body.properties == {}
    error_message = "The health model body must contain an empty properties object."
  }

  assert {
    condition     = toset(azapi_resource.this.response_export_values) == toset(["identity.principalId", "identity.tenantId"])
    error_message = "The primary resource must export only the system identity fields."
  }

  assert {
    condition     = length(azapi_resource.this.replace_triggers_refs) == 0
    error_message = "The primary resource has no immutable body properties requiring replacement."
  }

  assert {
    condition     = endswith(azapi_update_resource.root_entity.resource_id, "/entities/${var.name}") && azapi_update_resource.root_entity.body.properties.signalGroups.dependencies.aggregationType == "WorstOf"
    error_message = "The managed root entity must use the model name and default to WorstOf dependency aggregation."
  }

  assert {
    condition     = output.system_assigned_mi_principal_id == "11111111-1111-1111-1111-111111111111"
    error_message = "The module must expose the system-assigned managed identity principal ID."
  }
}

run "minimal_defaults" {
  command = apply

  assert {
    condition = (
      length(output.authentication_setting_resource_ids) == 0 &&
      length(output.entity_resource_ids) == 0 &&
      length(output.signal_definition_resource_ids) == 0 &&
      length(output.relationship_resource_ids) == 0 &&
      length(output.discovery_rule_resource_ids) == 0
    )
    error_message = "Minimal defaults must not create optional CloudHealth child resources."
  }

  assert {
    condition     = output.root_entity_resource_id != null && endswith(azapi_update_resource.root_entity.resource_id, "/entities/${var.name}")
    error_message = "Minimal defaults must still manage the correctly named root entity."
  }

  assert {
    condition     = length(azapi_resource.lock) == 0 && length(azapi_resource.role_assignment) == 0 && length(azapi_resource.diagnostic_setting) == 0
    error_message = "Minimal defaults must not create optional interface resources."
  }
}

run "invalid_name" {
  command = plan

  variables {
    name = "1x"
  }

  expect_failures = [
    var.name,
  ]
}

run "invalid_parent_id" {
  command = plan

  variables {
    parent_id = "/subscriptions/not-a-resource-group"
  }

  expect_failures = [
    var.parent_id,
  ]
}

run "rich_typed_model" {
  command = apply

  variables {
    managed_identities = {
      system_assigned = true
      user_assigned_resource_ids = [
        "/subscriptions/00000000-0000-0000-0000-000000000000/resourceGroups/rg-health/providers/Microsoft.ManagedIdentity/userAssignedIdentities/id-health"
      ]
    }
    authentication_settings = {
      system = {
        name                  = "auth-system"
        display_name          = "System identity"
        managed_identity_name = "SystemAssigned"
      }
      shared = {
        name                  = "auth-shared"
        display_name          = "Shared identity"
        managed_identity_name = "/subscriptions/00000000-0000-0000-0000-000000000000/resourceGroups/rg-health/providers/Microsoft.ManagedIdentity/userAssignedIdentities/id-health"
      }
    }
    signal_definitions = {
      metric = {
        name             = "metric-availability"
        display_name     = "Availability"
        signal_kind      = "AzureResourceMetric"
        data_unit        = "Percent"
        refresh_interval = "PT5M"
        metric_namespace = "Microsoft.Storage/storageAccounts"
        metric_name      = "Availability"
        aggregation_type = "Average"
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
      }
      promql = {
        name             = "promql-restarts"
        display_name     = "Pod restarts"
        signal_kind      = "PrometheusMetricsQuery"
        data_unit        = "Count"
        refresh_interval = "PT1M"
        query_text       = "sum(rate(kube_pod_container_status_restarts_total[5m])) or vector(0)"
        time_grain       = "PT5M"
        evaluation_rules = {
          degraded_rule = {
            operator  = "GreaterThan"
            threshold = 2
          }
          unhealthy_rule = {
            operator  = "GreaterThan"
            threshold = 8
          }
        }
      }
      kql = {
        name              = "kql-errors"
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
    }
    entities = {
      storage = {
        name         = "storage"
        display_name = "Storage account"
        impact       = "Standard"
        signal_groups = {
          azure_resource = {
            authentication_setting = "auth-system"
            azure_resource_id      = "/subscriptions/00000000-0000-0000-0000-000000000000/resourceGroups/rg-health/providers/Microsoft.Storage/storageAccounts/sthealth"
            resource_health = {
              enabled = "Enabled"
            }
            signals = [
              {
                name                   = "availability"
                signal_definition_name = "metric-availability"
              },
              {
                name             = "transactions"
                display_name     = "Transactions"
                metric_namespace = "Microsoft.Storage/storageAccounts"
                metric_name      = "Transactions"
                aggregation_type = "Total"
                data_unit        = "Count"
                refresh_interval = "PT5M"
                time_grain       = "PT5M"
                evaluation_rules = {
                  unhealthy_rule = {
                    operator         = "Dynamic"
                    sensitivity      = "Medium"
                    look_back_window = "PT15M"
                  }
                }
              }
            ]
          }
        }
      }
      compute = {
        name         = "compute"
        display_name = "Compute"
        signal_groups = {
          azure_monitor_workspace = {
            authentication_setting              = "auth-shared"
            azure_monitor_workspace_resource_id = "/subscriptions/00000000-0000-0000-0000-000000000000/resourceGroups/rg-health/providers/Microsoft.Monitor/accounts/amw-health"
            signals = [
              {
                name                   = "restarts-shared"
                signal_definition_name = "promql-restarts"
              },
              {
                name             = "pods-unavailable"
                query_text       = "sum(kube_deployment_status_replicas_unavailable) or vector(0)"
                data_unit        = "Count"
                refresh_interval = "PT1M"
                time_grain       = "PT5M"
                evaluation_rules = {
                  unhealthy_rule = {
                    operator  = "GreaterThan"
                    threshold = 4
                  }
                }
              },
              {
                name             = "pods-pending"
                query_text       = "sum(kube_pod_status_phase{phase=\"Pending\"}) or vector(0)"
                data_unit        = "Count"
                refresh_interval = "PT5M"
                evaluation_rules = {
                  unhealthy_rule = {
                    operator  = "GreaterThanOrEqual"
                    threshold = 9
                  }
                }
              }
            ]
          }
        }
      }
      application = {
        name         = "application"
        display_name = "Application"
        signal_groups = {
          azure_log_analytics = {
            authentication_setting              = "auth-shared"
            log_analytics_workspace_resource_id = "/subscriptions/00000000-0000-0000-0000-000000000000/resourceGroups/rg-health/providers/Microsoft.OperationalInsights/workspaces/law-health"
            signals = [
              {
                name                   = "errors-shared"
                signal_definition_name = "kql-errors"
              },
              {
                name              = "timeouts"
                query_text        = "AppRequests | where DurationMs > 30000 | summarize Count=count()"
                value_column_name = "Count"
                data_unit         = "Count"
                refresh_interval  = "PT5M"
                time_grain        = "PT5M"
                evaluation_rules = {
                  unhealthy_rule = {
                    operator  = "GreaterThan"
                    threshold = 20
                  }
                }
              },
              {
                name              = "dependencies"
                query_text        = "AppDependencies | where Success == false | summarize Count=count()"
                value_column_name = "Count"
                data_unit         = "Count"
                refresh_interval  = "PT10M"
                evaluation_rules = {
                  unhealthy_rule = {
                    operator  = "GreaterThan"
                    threshold = 30
                  }
                }
              },
              {
                name              = "exceptions"
                query_text        = "AppExceptions | summarize Count=count()"
                value_column_name = "Count"
                data_unit         = "Count"
                refresh_interval  = "PT15M"
                evaluation_rules = {
                  unhealthy_rule = {
                    operator  = "GreaterThan"
                    threshold = 40
                  }
                }
              }
            ]
          }
        }
      }
      platform = {
        name         = "platform"
        display_name = "Platform"
        signal_groups = {
          dependencies = {
            aggregation_type    = "MinHealthy"
            unit                = "Percentage"
            degraded_threshold  = 80
            unhealthy_threshold = 60
            ignore_unknown      = false
          }
        }
      }
      embedded = {
        name         = "embedded"
        display_name = "Embedded child model"
        signal_groups = {
          embedded_health_model = {
            authentication_setting = "auth-shared"
            resource_id            = "/subscriptions/00000000-0000-0000-0000-000000000000/resourceGroups/rg-health/providers/Microsoft.CloudHealth/healthmodels/hm-child"
          }
        }
      }
    }
    relationships = {
      root_platform = {
        name               = "root-platform"
        parent_entity_name = "hm-root-test"
        child_entity_name  = "platform"
      }
      platform_storage = {
        name               = "platform-storage"
        parent_entity_name = "platform"
        child_entity_name  = "storage"
      }
      platform_compute = {
        name               = "platform-compute"
        parent_entity_name = "platform"
        child_entity_name  = "compute"
      }
      root_application = {
        name               = "root-application"
        parent_entity_name = "hm-root-test"
        child_entity_name  = "application"
      }
    }
    discovery_rules = {
      graph = {
        name                       = "discover-storage"
        display_name               = "Discover storage"
        authentication_setting     = "auth-system"
        discover_relationships     = "Enabled"
        add_recommended_signals    = "Enabled"
        add_resource_health_signal = "Enabled"
        specification = {
          kind                 = "ResourceGraphQuery"
          resource_graph_query = "resources | where type =~ 'microsoft.storage/storageaccounts' | project id"
        }
      }
      app_insights = {
        name                    = "discover-application"
        display_name            = "Discover application"
        authentication_setting  = "auth-shared"
        discover_relationships  = "Disabled"
        add_recommended_signals = "Disabled"
        specification = {
          kind                             = "ApplicationInsightsTopology"
          application_insights_resource_id = "/subscriptions/00000000-0000-0000-0000-000000000000/resourceGroups/rg-health/providers/Microsoft.Insights/components/app-health"
        }
      }
    }
  }

  assert {
    condition     = length(output.authentication_setting_resource_ids) == 2
    error_message = "The rich model must create two authentication settings."
  }

  assert {
    condition     = length(output.entity_resource_ids) == 5 && output.root_entity_resource_id != null
    error_message = "The rich model must create five caller entities plus the managed root."
  }

  assert {
    condition     = length(output.signal_definition_resource_ids) == 3
    error_message = "The rich model must create all three reusable signal kinds."
  }

  assert {
    condition     = length(output.relationship_resource_ids) == 4
    error_message = "The rich model must preserve varied relationship cardinality."
  }

  assert {
    condition     = length(output.discovery_rule_resource_ids) == 2
    error_message = "The rich model must create both discovery variants."
  }

  assert {
    condition = (
      module.entity["storage"].inline_signal_counts.azure_resource == 2 &&
      module.entity["compute"].inline_signal_counts.azure_monitor_workspace == 3 &&
      module.entity["application"].inline_signal_counts.azure_log_analytics == 4
    )
    error_message = "The rich model must preserve varied Azure metric, PromQL, and KQL signal counts."
  }
}

run "dangling_relationship_endpoint" {
  command = plan

  variables {
    relationships = {
      invalid = {
        name               = "invalid-edge"
        parent_entity_name = "hm-root-test"
        child_entity_name  = "missing-entity"
      }
    }
  }

  expect_failures = [
    azapi_resource.this,
  ]
}

run "missing_authentication_reference" {
  command = plan

  variables {
    entities = {
      invalid = {
        name = "invalid-entity"
        signal_groups = {
          azure_resource = {
            authentication_setting = "missing-auth"
            azure_resource_id      = "/subscriptions/00000000-0000-0000-0000-000000000000/resourceGroups/rg-health/providers/Microsoft.Storage/storageAccounts/sthealth"
          }
        }
      }
    }
  }

  expect_failures = [
    azapi_resource.this,
  ]
}

run "missing_signal_kind_fields" {
  command = plan

  variables {
    signal_definitions = {
      invalid = {
        name             = "invalid-metric"
        signal_kind      = "AzureResourceMetric"
        aggregation_type = "Average"
        time_grain       = "PT5M"
        evaluation_rules = {
          unhealthy_rule = {
            operator  = "LessThan"
            threshold = 90
          }
        }
      }
    }
  }

  expect_failures = [
    var.signal_definitions,
  ]
}

run "model_of_models" {
  command = apply

  variables {
    managed_identities = {
      system_assigned = true
    }
    authentication_settings = {
      system = {
        name                  = "auth-system"
        managed_identity_name = "SystemAssigned"
      }
    }
    entities = {
      child_model = {
        name = "child-model"
        signal_groups = {
          embedded_health_model = {
            authentication_setting = "auth-system"
            resource_id            = "/subscriptions/00000000-0000-0000-0000-000000000000/resourceGroups/rg-health/providers/Microsoft.CloudHealth/healthmodels/hm-child"
          }
        }
      }
    }
    relationships = {
      root_child = {
        name               = "root-child-model"
        parent_entity_name = "hm-root-test"
        child_entity_name  = "child-model"
      }
    }
  }

  assert {
    condition     = module.entity["child_model"].azure_resource_id == "/subscriptions/00000000-0000-0000-0000-000000000000/resourceGroups/rg-health/providers/Microsoft.CloudHealth/healthmodels/hm-child"
    error_message = "The embedded entity must point its Azure-resource signal group at the child health model."
  }

  assert {
    condition     = !module.entity["child_model"].has_inline_signals
    error_message = "The embedded entity must not contain inline signals."
  }
}

run "invalid_embedded_health_model_id" {
  command = plan

  variables {
    entities = {
      invalid = {
        name = "invalid-embedded"
        signal_groups = {
          embedded_health_model = {
            authentication_setting = "auth-system"
            resource_id            = "/subscriptions/00000000-0000-0000-0000-000000000000/resourceGroups/rg-health/providers/Microsoft.Storage/storageAccounts/not-a-model"
          }
        }
      }
    }
  }

  expect_failures = [
    var.entities,
  ]
}

run "unattached_authentication_identity" {
  command = plan

  variables {
    authentication_settings = {
      invalid = {
        name                  = "auth-unattached"
        managed_identity_name = "/subscriptions/00000000-0000-0000-0000-000000000000/resourceGroups/rg-health/providers/Microsoft.ManagedIdentity/userAssignedIdentities/not-attached"
      }
    }
  }

  expect_failures = [
    azapi_resource.this,
  ]
}

run "invalid_entity_impact" {
  command = plan

  variables {
    entities = {
      invalid = {
        name   = "invalid-impact"
        impact = "Catastrophic"
      }
    }
  }

  expect_failures = [
    var.entities,
  ]
}

run "malformed_log_analytics_workspace_id" {
  command = plan

  variables {
    entities = {
      invalid = {
        name = "invalid-workspace"
        signal_groups = {
          azure_log_analytics = {
            authentication_setting              = "auth-system"
            log_analytics_workspace_resource_id = "/subscriptions/00000000-0000-0000-0000-000000000000/resourceGroups/rg-health/providers/Microsoft.Storage/storageAccounts/not-a-workspace"
          }
        }
      }
    }
  }

  expect_failures = [
    var.entities,
  ]
}

run "invalid_signal_operator" {
  command = plan

  variables {
    signal_definitions = {
      invalid = {
        name             = "invalid-operator"
        signal_kind      = "AzureResourceMetric"
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
      }
    }
  }

  expect_failures = [
    var.signal_definitions,
  ]
}

run "resource_type_overrides_cascade" {
  command = plan

  variables {
    managed_identities = {
      system_assigned = true
    }
    authentication_settings = {
      system = {
        name                  = "auth-system"
        managed_identity_name = "SystemAssigned"
      }
    }

    signal_definitions = {
      metric = {
        name             = "metric-availability"
        signal_kind      = "AzureResourceMetric"
        metric_namespace = "Microsoft.Storage/storageAccounts"
        metric_name      = "Availability"
        aggregation_type = "Average"
        time_grain       = "PT5M"
        evaluation_rules = {
          unhealthy_rule = {
            operator  = "LessThan"
            threshold = 99
          }
        }
      }
    }
    entities = {
      workload = {
        name = "workload"
      }
    }
    relationships = {
      root_workload = {
        name               = "root-workload"
        parent_entity_name = "hm-root-test"
        child_entity_name  = "workload"
      }
    }
    discovery_rules = {
      graph = {
        name                    = "discover-resources"
        authentication_setting  = "auth-system"
        discover_relationships  = "Enabled"
        add_recommended_signals = "Disabled"
        specification = {
          kind                 = "ResourceGraphQuery"
          resource_graph_query = "resources | project id"
        }
      }
    }
    resource_types = {
      cloudhealth_healthmodels = "Microsoft.CloudHealth/healthModels@2026-05-01-preview"
      cloudhealth_healthmodels_authenticationsettings = {
        cloudhealth_healthmodels_authenticationsettings = "Microsoft.CloudHealth/healthModels/authenticationSettings@2026-05-01-preview"
      }
      cloudhealth_healthmodels_entities = {
        cloudhealth_healthmodels_entities = "Microsoft.CloudHealth/healthModels/entities@2026-05-01-preview"
      }
      cloudhealth_healthmodels_signaldefinitions = {
        cloudhealth_healthmodels_signaldefinitions = "Microsoft.CloudHealth/healthModels/signalDefinitions@2026-05-01-preview"
      }
      cloudhealth_healthmodels_relationships = {
        cloudhealth_healthmodels_relationships = "Microsoft.CloudHealth/healthModels/relationships@2026-05-01-preview"
      }
      cloudhealth_healthmodels_discoveryrules = {
        cloudhealth_healthmodels_discoveryrules = "Microsoft.CloudHealth/healthModels/discoveryRules@2026-05-01-preview"
      }
    }
  }

  assert {
    condition     = azapi_resource.this.type == "Microsoft.CloudHealth/healthModels@2026-05-01-preview"
    error_message = "The root resource type override must use the deterministic ARM-derived key."
  }

  assert {
    condition     = azapi_update_resource.root_entity.type == "Microsoft.CloudHealth/healthModels/entities@2026-05-01-preview"
    error_message = "The root entity must use the entity submodule's nested resource type slot."
  }

  assert {
    condition = (
      length(module.authentication_setting) == 1 &&
      length(module.entity) == 1 &&
      length(module.signal_definition) == 1 &&
      length(module.relationship) == 1 &&
      length(module.discovery_rule) == 1
    )
    error_message = "The nested resource type override must preserve all five child-module calls."
  }
}

run "invalid_inline_signal_operator" {
  command = plan

  variables {
    managed_identities = {
      system_assigned = true
    }
    authentication_settings = {
      system = {
        name                  = "auth-system"
        managed_identity_name = "SystemAssigned"
      }
    }
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

run "degraded_dynamic_inline_rule" {
  command = plan

  variables {
    managed_identities = {
      system_assigned = true
    }
    authentication_settings = {
      system = {
        name                  = "auth-system"
        managed_identity_name = "SystemAssigned"
      }
    }
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

run "dynamic_rule_missing_configuration" {
  command = plan

  variables {
    signal_definitions = {
      invalid = {
        name             = "dynamic-missing-fields"
        signal_kind      = "AzureResourceMetric"
        metric_namespace = "Microsoft.Storage/storageAccounts"
        metric_name      = "Availability"
        aggregation_type = "Average"
        time_grain       = "PT5M"
        evaluation_rules = {
          unhealthy_rule = {
            operator = "Dynamic"
          }
        }
      }
    }
  }

  expect_failures = [
    var.signal_definitions,
  ]
}

run "static_rule_rejects_dynamic_fields" {
  command = plan

  variables {
    signal_definitions = {
      invalid = {
        name             = "static-with-dynamic-fields"
        signal_kind      = "AzureResourceMetric"
        metric_namespace = "Microsoft.Storage/storageAccounts"
        metric_name      = "Availability"
        aggregation_type = "Average"
        time_grain       = "PT5M"
        evaluation_rules = {
          unhealthy_rule = {
            operator         = "LessThan"
            threshold        = 99
            sensitivity      = "High"
            look_back_window = "PT30M"
          }
        }
      }
    }
  }

  expect_failures = [
    var.signal_definitions,
  ]
}

run "invalid_dynamic_rule_enums" {
  command = plan

  variables {
    signal_definitions = {
      invalid = {
        name             = "dynamic-invalid-enums"
        signal_kind      = "AzureResourceMetric"
        metric_namespace = "Microsoft.Storage/storageAccounts"
        metric_name      = "Availability"
        aggregation_type = "Average"
        time_grain       = "PT5M"
        evaluation_rules = {
          unhealthy_rule = {
            operator         = "Dynamic"
            sensitivity      = "Extreme"
            look_back_window = "PT2H"
          }
        }
      }
    }
  }

  expect_failures = [
    var.signal_definitions,
  ]
}

run "dynamic_rule_rejects_query_signal_kind" {
  command = plan

  variables {
    signal_definitions = {
      invalid = {
        name             = "dynamic-on-kql"
        signal_kind      = "LogAnalyticsQuery"
        query_text       = "AppExceptions | summarize Count=count()"
        time_grain       = "PT15M"
        refresh_interval = "PT5M"
        evaluation_rules = {
          unhealthy_rule = {
            operator         = "Dynamic"
            sensitivity      = "Medium"
            look_back_window = "PT30M"
          }
        }
      }
    }
  }

  expect_failures = [
    var.signal_definitions,
  ]
}

run "dynamic_inline_rule_rejects_query_signal_group" {
  command = plan

  variables {
    managed_identities = {
      system_assigned = true
    }
    authentication_settings = {
      system = {
        name                  = "auth-system"
        managed_identity_name = "SystemAssigned"
      }
    }
    entities = {
      invalid = {
        name = "invalid-dynamic-kql"
        signal_groups = {
          azure_log_analytics = {
            authentication_setting              = "auth-system"
            log_analytics_workspace_resource_id = "/subscriptions/00000000-0000-0000-0000-000000000000/resourceGroups/rg-health/providers/Microsoft.OperationalInsights/workspaces/law-health"
            signals = [{
              name              = "exceptions"
              query_text        = "AppExceptions | summarize Count=count()"
              value_column_name = "Count"
              time_grain        = "PT15M"
              refresh_interval  = "PT5M"
              evaluation_rules = {
                unhealthy_rule = {
                  operator         = "Dynamic"
                  sensitivity      = "Medium"
                  look_back_window = "PT30M"
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

run "refresh_interval_exceeding_time_grain" {
  command = plan

  variables {
    signal_definitions = {
      invalid = {
        name             = "refresh-faster-than-grain"
        signal_kind      = "AzureResourceMetric"
        metric_namespace = "Microsoft.Storage/storageAccounts"
        metric_name      = "Availability"
        aggregation_type = "Average"
        time_grain       = "PT5M"
        refresh_interval = "PT15M"
        evaluation_rules = {
          unhealthy_rule = {
            operator  = "LessThan"
            threshold = 99
          }
        }
      }
    }
  }

  expect_failures = [
    azapi_resource.this,
  ]
}

run "dynamic_rule_rejects_sub_five_minute_time_grain" {
  command = plan

  variables {
    signal_definitions = {
      invalid = {
        name             = "dynamic-one-minute-grain"
        signal_kind      = "AzureResourceMetric"
        metric_namespace = "Microsoft.Storage/storageAccounts"
        metric_name      = "Availability"
        aggregation_type = "Average"
        time_grain       = "PT1M"
        refresh_interval = "PT1M"
        evaluation_rules = {
          unhealthy_rule = {
            operator         = "Dynamic"
            sensitivity      = "Medium"
            look_back_window = "PT30M"
          }
        }
      }
    }
  }

  expect_failures = [
    azapi_resource.this,
  ]
}

run "dynamic_inline_rule_inherits_time_grain_from_definition" {
  command = plan

  variables {
    managed_identities = {
      system_assigned = true
    }
    authentication_settings = {
      system = {
        name                  = "auth-system"
        managed_identity_name = "SystemAssigned"
      }
    }
    signal_definitions = {
      cpu = {
        name             = "cpu-def"
        signal_kind      = "AzureResourceMetric"
        metric_namespace = "Microsoft.Storage/storageAccounts"
        metric_name      = "Availability"
        aggregation_type = "Average"
        time_grain       = "PT15M"
        evaluation_rules = {
          unhealthy_rule = {
            operator  = "LessThan"
            threshold = 99
          }
        }
      }
    }
    entities = {
      storage = {
        name = "inherited-grain"
        signal_groups = {
          azure_resource = {
            authentication_setting = "auth-system"
            azure_resource_id      = "/subscriptions/00000000-0000-0000-0000-000000000000/resourceGroups/rg-health/providers/Microsoft.Storage/storageAccounts/sthealth"
            signals = [{
              name                   = "cpu"
              signal_definition_name = "cpu-def"
              evaluation_rules = {
                unhealthy_rule = {
                  operator         = "Dynamic"
                  sensitivity      = "Medium"
                  look_back_window = "PT30M"
                }
              }
            }]
          }
        }
      }
    }
  }

  assert {
    condition     = length(output.entity_resource_ids) == 1
    error_message = "A Dynamic rule on a signal that inherits its time grain from a referenced definition must be accepted."
  }
}

run "dynamic_inline_rule_requires_time_grain" {
  command = plan

  variables {
    managed_identities = {
      system_assigned = true
    }
    authentication_settings = {
      system = {
        name                  = "auth-system"
        managed_identity_name = "SystemAssigned"
      }
    }
    entities = {
      invalid = {
        name = "invalid-dynamic-no-grain"
        signal_groups = {
          azure_resource = {
            authentication_setting = "auth-system"
            azure_resource_id      = "/subscriptions/00000000-0000-0000-0000-000000000000/resourceGroups/rg-health/providers/Microsoft.Storage/storageAccounts/sthealth"
            signals = [{
              name             = "availability"
              metric_namespace = "Microsoft.Storage/storageAccounts"
              metric_name      = "Availability"
              aggregation_type = "Average"
              evaluation_rules = {
                unhealthy_rule = {
                  operator         = "Dynamic"
                  sensitivity      = "Medium"
                  look_back_window = "PT30M"
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

run "degraded_rule_beside_dynamic_unhealthy_rule" {
  command = plan

  variables {
    signal_definitions = {
      invalid = {
        name             = "dynamic-with-degraded"
        signal_kind      = "AzureResourceMetric"
        metric_namespace = "Microsoft.Storage/storageAccounts"
        metric_name      = "Availability"
        aggregation_type = "Average"
        time_grain       = "PT5M"
        evaluation_rules = {
          degraded_rule = {
            operator  = "LessThan"
            threshold = 99
          }
          unhealthy_rule = {
            operator         = "Dynamic"
            sensitivity      = "Medium"
            look_back_window = "PT30M"
          }
        }
      }
    }
  }

  expect_failures = [
    azapi_resource.this,
  ]
}

run "unrecognised_time_grain_is_accepted" {
  command = plan

  variables {
    signal_definitions = {
      unusual = {
        name             = "seven-minute-grain"
        signal_kind      = "AzureResourceMetric"
        metric_namespace = "Microsoft.Storage/storageAccounts"
        metric_name      = "Availability"
        aggregation_type = "Average"
        time_grain       = "PT7M"
        refresh_interval = "PT5M"
        evaluation_rules = {
          unhealthy_rule = {
            operator  = "LessThan"
            threshold = 99
          }
        }
      }
    }
  }

  assert {
    condition     = length(output.signal_definition_resource_ids) == 1
    error_message = "The CloudHealth API types `timeGrain` as a free-form ISO 8601 string, so a grain outside the module lookup must not be rejected."
  }
}

run "lock_teardown_retry" {
  command = plan

  variables {
    lock = {
      kind = "CanNotDelete"
    }
  }

  assert {
    condition = (
      contains(try(azapi_resource.this.retry.error_message_regex, []), "ScopeLocked") &&
      try(azapi_resource.this.retry.interval_seconds, 0) == 15 &&
      try(azapi_resource.this.retry.max_interval_seconds, 0) == 60 &&
      contains(try(azapi_resource.lock[0].retry.error_message_regex, []), "ScopeLocked") &&
      contains(try(azapi_update_resource.root_entity.retry.error_message_regex, []), "ScopeLocked")
    )
    error_message = "The root and lock resources must narrowly retry ScopeLocked while Azure propagates lock removal."
  }
}

run "diagnostic_defaults_exclude_metrics" {
  command = plan

  variables {
    diagnostic_settings = {
      workspace = {
        workspace_resource_id = "/subscriptions/00000000-0000-0000-0000-000000000000/resourceGroups/rg-health/providers/Microsoft.OperationalInsights/workspaces/law-health"
      }
    }
  }

  assert {
    condition     = try(length(azapi_resource.diagnostic_setting["workspace"].body.properties.metrics), 0) == 0
    error_message = "CloudHealth diagnostic settings must not default to AllMetrics because the service does not support metric export."
  }

  assert {
    condition     = contains(try(azapi_resource.diagnostic_setting["workspace"].retry.error_message_regex, []), "ScopeLocked")
    error_message = "Diagnostic setting deletion must retry the narrow lock-removal propagation error."
  }
}

run "diagnostic_metric_override_is_preserved" {
  command = plan

  variables {
    diagnostic_settings = {
      workspace = {
        metric_categories     = ["CallerSelectedMetric"]
        workspace_resource_id = "/subscriptions/00000000-0000-0000-0000-000000000000/resourceGroups/rg-health/providers/Microsoft.OperationalInsights/workspaces/law-health"
      }
    }
  }

  assert {
    condition = (
      length(azapi_resource.diagnostic_setting["workspace"].body.properties.metrics) == 1 &&
      one(azapi_resource.diagnostic_setting["workspace"].body.properties.metrics).category == "CallerSelectedMetric"
    )
    error_message = "An explicit diagnostic metric category must pass through unchanged even though CloudHealth defaults metric export to empty."
  }
}

run "role_assignment_lock_removal_retry" {
  command = plan

  variables {
    role_assignments = {
      reader = {
        principal_id               = "11111111-1111-1111-1111-111111111111"
        role_definition_id_or_name = "/subscriptions/00000000-0000-0000-0000-000000000000/providers/Microsoft.Authorization/roleDefinitions/acdd72a7-3385-48ef-bd42-f606fba81ae7"
      }
    }
  }

  assert {
    condition = (
      length(azapi_resource.role_assignment) == 1 &&
      contains(try(one(values(azapi_resource.role_assignment)).retry.error_message_regex, []), "ScopeLocked")
    )
    error_message = "Role assignment deletion must retry the narrow lock-removal propagation error."
  }
}

run "relationship_to_discovery_entity" {
  command = plan

  variables {
    managed_identities = {
      system_assigned = true
    }
    authentication_settings = {
      system = {
        name                  = "auth-system"
        managed_identity_name = "SystemAssigned"
      }
    }
    discovery_rules = {
      storage = {
        name                    = "discover-storage"
        authentication_setting  = "auth-system"
        discover_relationships  = "Disabled"
        add_recommended_signals = "Enabled"
        specification = {
          kind                 = "ResourceGraphQuery"
          resource_graph_query = "resources | where type =~ 'microsoft.storage/storageaccounts' | project id"
        }
      }
    }
    relationships = {
      root_discovery = {
        name               = "root-discovery"
        parent_entity_name = "hm-root-test"
        child_entity_name  = "discover-storage"
      }
    }
  }

  assert {
    condition = (
      length(output.discovery_rule_resource_ids) == 1 &&
      length(output.relationship_resource_ids) == 1
    )
    error_message = "A discovery rule's deterministic entity name must be a valid relationship endpoint."
  }
}
