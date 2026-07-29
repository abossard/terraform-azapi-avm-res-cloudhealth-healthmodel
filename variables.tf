variable "location" {
  type        = string
  description = "THIS IS A VARIABLE USED FOR A PREVIEW SERVICE/FEATURE, MICROSOFT MAY NOT PROVIDE SUPPORT FOR THIS, PLEASE CHECK THE PRODUCT DOCS FOR CLARIFICATION. The Azure region in which to create the health model. Query current CloudHealth availability before deployment."
  nullable    = false

  validation {
    condition     = length(trimspace(var.location)) > 0
    error_message = "`location` must not be empty."
  }
}

variable "name" {
  type        = string
  description = "THIS IS A VARIABLE USED FOR A PREVIEW SERVICE/FEATURE, MICROSOFT MAY NOT PROVIDE SUPPORT FOR THIS, PLEASE CHECK THE PRODUCT DOCS FOR CLARIFICATION. The name of the CloudHealth health model."
  nullable    = false

  validation {
    condition     = can(regex("^[a-zA-Z][a-zA-Z0-9-]{1,42}[a-zA-Z0-9]$", var.name))
    error_message = "`name` must be 3-44 characters, start with a letter, end with an alphanumeric character, and contain only letters, numbers, and hyphens."
  }
}

variable "parent_id" {
  type        = string
  description = "THIS IS A VARIABLE USED FOR A PREVIEW SERVICE/FEATURE, MICROSOFT MAY NOT PROVIDE SUPPORT FOR THIS, PLEASE CHECK THE PRODUCT DOCS FOR CLARIFICATION. The resource ID of the resource group in which to create the health model."
  nullable    = false

  validation {
    condition     = can(provider::azapi::parse_resource_id("Microsoft.Resources/resourceGroups", var.parent_id))
    error_message = "`parent_id` must be a valid resource group resource ID."
  }
}

variable "authentication_settings" {
  type = map(object({
    name                  = string
    display_name          = optional(string)
    managed_identity_name = string
  }))
  default     = {}
  description = "THIS IS A VARIABLE USED FOR A PREVIEW SERVICE/FEATURE, MICROSOFT MAY NOT PROVIDE SUPPORT FOR THIS, PLEASE CHECK THE PRODUCT DOCS FOR CLARIFICATION. Authentication settings keyed by arbitrary Terraform-stable keys."
  nullable    = false

  validation {
    condition = alltrue([
      for setting in var.authentication_settings :
      can(regex("^[a-zA-Z0-9][a-zA-Z0-9-]{1,258}[a-zA-Z0-9]$", setting.name))
    ])
    error_message = "Every authentication setting name must be 3-260 alphanumeric or hyphen characters and start and end with an alphanumeric character."
  }
  validation {
    condition = alltrue([
      for setting in var.authentication_settings :
      setting.managed_identity_name == "SystemAssigned" || can(provider::azapi::parse_resource_id("Microsoft.ManagedIdentity/userAssignedIdentities", setting.managed_identity_name))
    ])
    error_message = "Every `managed_identity_name` must be `SystemAssigned` or a valid user-assigned managed identity resource ID."
  }
}

variable "diagnostic_settings" {
  type = map(object({
    name                                     = optional(string, null)
    log_categories                           = optional(set(string), [])
    log_groups                               = optional(set(string), ["allLogs"])
    metric_categories                        = optional(set(string), ["AllMetrics"])
    log_analytics_destination_type           = optional(string, "Dedicated")
    workspace_resource_id                    = optional(string, null)
    storage_account_resource_id              = optional(string, null)
    event_hub_authorization_rule_resource_id = optional(string, null)
    event_hub_name                           = optional(string, null)
    marketplace_partner_resource_id          = optional(string, null)
  }))
  default     = {}
  description = "Diagnostic settings to create on the health model. The standard AVM interface defaults `metric_categories` to `[\"AllMetrics\"]`; because CloudHealth currently reports `DS Export: No`, this module maps that sentinel default to an empty deployed set while preserving any other caller-supplied category set."
  nullable    = false
}

variable "discovery_rules" {
  type = map(object({
    name                       = string
    display_name               = optional(string)
    authentication_setting     = string
    discover_relationships     = string
    add_recommended_signals    = string
    add_resource_health_signal = optional(string)
    specification = object({
      kind                             = string
      resource_graph_query             = optional(string)
      application_insights_resource_id = optional(string)
    })
  }))
  default     = {}
  description = "THIS IS A VARIABLE USED FOR A PREVIEW SERVICE/FEATURE, MICROSOFT MAY NOT PROVIDE SUPPORT FOR THIS, PLEASE CHECK THE PRODUCT DOCS FOR CLARIFICATION. Discovery rules keyed by arbitrary Terraform-stable keys."
  nullable    = false

  validation {
    condition = alltrue([
      for rule in var.discovery_rules :
      contains(["Enabled", "Disabled"], rule.discover_relationships) &&
      contains(["Enabled", "Disabled"], rule.add_recommended_signals) &&
      (rule.add_resource_health_signal == null || contains(["Enabled", "Disabled"], rule.add_resource_health_signal))
    ])
    error_message = "Discovery behavior values must be `Enabled` or `Disabled`."
  }
  validation {
    condition = alltrue([
      for rule in var.discovery_rules :
      rule.specification.kind == "ResourceGraphQuery" ? (
        rule.specification.resource_graph_query != null &&
        rule.specification.application_insights_resource_id == null
        ) : rule.specification.kind == "ApplicationInsightsTopology" ? (
        rule.specification.application_insights_resource_id != null &&
        rule.specification.resource_graph_query == null
      ) : false
    ])
    error_message = "ResourceGraphQuery specifications require only `resource_graph_query`; ApplicationInsightsTopology specifications require only `application_insights_resource_id`."
  }
  validation {
    condition = alltrue([
      for rule in var.discovery_rules :
      rule.specification.application_insights_resource_id == null || can(provider::azapi::parse_resource_id("Microsoft.Insights/components", rule.specification.application_insights_resource_id))
    ])
    error_message = "Every Application Insights topology ID must identify a `Microsoft.Insights/components` resource."
  }
}

variable "enable_telemetry" {
  type        = bool
  default     = true
  description = <<DESCRIPTION
This variable controls whether or not telemetry is enabled for the module.
For more information see <https://aka.ms/avm/telemetryinfo>.
If it is set to false, then no telemetry will be collected.
DESCRIPTION
  nullable    = false
}

variable "entities" {
  type = map(object({
    name         = string
    display_name = optional(string)
    canvas_position = optional(object({
      x = number
      y = number
    }))
    icon = optional(object({
      icon_name   = string
      custom_data = optional(string)
    }))
    health_objective = optional(number)
    impact           = optional(string, "Standard")
    tags             = optional(map(string))
    alerts = optional(object({
      degraded = optional(object({
        severity         = string
        description      = optional(string)
        action_group_ids = optional(set(string), [])
      }))
      unhealthy = optional(object({
        severity         = string
        description      = optional(string)
        action_group_ids = optional(set(string), [])
      }))
    }))
    signal_groups = optional(object({
      azure_resource = optional(object({
        authentication_setting = string
        azure_resource_id      = string
        azure_resource_kind    = optional(string)
        resource_health = optional(object({
          enabled = optional(string, "Enabled")
        }))
        signals = optional(list(object({
          name                   = string
          signal_definition_name = optional(string)
          display_name           = optional(string)
          metric_namespace       = optional(string)
          metric_name            = optional(string)
          aggregation_type       = optional(string)
          dimension_filter       = optional(string)
          data_unit              = optional(string)
          refresh_interval       = optional(string, "PT1M")
          time_grain             = optional(string)
          evaluation_rules = optional(object({
            degraded_rule = optional(object({
              operator         = string
              threshold        = optional(number)
              sensitivity      = optional(string)
              look_back_window = optional(string)
            }))
            unhealthy_rule = object({
              operator         = string
              threshold        = optional(number)
              sensitivity      = optional(string)
              look_back_window = optional(string)
            })
          }))
        })), [])
      }))
      embedded_health_model = optional(object({
        authentication_setting = string
        resource_id            = string
      }))
      azure_monitor_workspace = optional(object({
        authentication_setting              = string
        azure_monitor_workspace_resource_id = string
        signals = optional(list(object({
          name                   = string
          signal_definition_name = optional(string)
          display_name           = optional(string)
          query_text             = optional(string)
          data_unit              = optional(string)
          refresh_interval       = optional(string, "PT1M")
          time_grain             = optional(string)
          evaluation_rules = optional(object({
            degraded_rule = optional(object({
              operator         = string
              threshold        = optional(number)
              sensitivity      = optional(string)
              look_back_window = optional(string)
            }))
            unhealthy_rule = object({
              operator         = string
              threshold        = optional(number)
              sensitivity      = optional(string)
              look_back_window = optional(string)
            })
          }))
        })), [])
      }))
      azure_log_analytics = optional(object({
        authentication_setting              = string
        log_analytics_workspace_resource_id = string
        signals = optional(list(object({
          name                   = string
          signal_definition_name = optional(string)
          display_name           = optional(string)
          query_text             = optional(string)
          data_unit              = optional(string)
          refresh_interval       = optional(string, "PT1M")
          time_grain             = optional(string)
          value_column_name      = optional(string)
          evaluation_rules = optional(object({
            degraded_rule = optional(object({
              operator         = string
              threshold        = optional(number)
              sensitivity      = optional(string)
              look_back_window = optional(string)
            }))
            unhealthy_rule = object({
              operator         = string
              threshold        = optional(number)
              sensitivity      = optional(string)
              look_back_window = optional(string)
            })
          }))
        })), [])
      }))
      dependencies = optional(object({
        aggregation_type    = optional(string, "WorstOf")
        degraded_threshold  = optional(number)
        unhealthy_threshold = optional(number)
        unit                = optional(string)
        ignore_unknown      = optional(bool, true)
      }))
    }), {})
  }))
  default     = {}
  description = "THIS IS A VARIABLE USED FOR A PREVIEW SERVICE/FEATURE, MICROSOFT MAY NOT PROVIDE SUPPORT FOR THIS, PLEASE CHECK THE PRODUCT DOCS FOR CLARIFICATION. Health model entities keyed by arbitrary Terraform-stable keys."
  nullable    = false

  validation {
    condition = alltrue([
      for entity in var.entities :
      entity.name != var.name
    ])
    error_message = "Caller-defined entity names cannot equal the health model name; configure the managed root through `root_entity`."
  }
  validation {
    condition = alltrue([
      for entity in var.entities :
      can(regex("^[a-zA-Z0-9][a-zA-Z0-9-]{1,258}[a-zA-Z0-9]$", entity.name))
    ])
    error_message = "Every entity name must be 3-260 alphanumeric or hyphen characters and start and end with an alphanumeric character."
  }
  validation {
    condition = alltrue([
      for entity in var.entities :
      contains(["Standard", "Limited", "Suppressed"], entity.impact)
    ])
    error_message = "Every entity impact must be `Standard`, `Limited`, or `Suppressed`."
  }
  validation {
    condition = alltrue([
      for entity in var.entities :
      !(entity.signal_groups.azure_resource != null && entity.signal_groups.embedded_health_model != null)
    ])
    error_message = "An entity cannot configure both `azure_resource` and `embedded_health_model` because both map to the ARM azureResource signal group."
  }
  validation {
    condition = alltrue([
      for entity in var.entities :
      entity.signal_groups.embedded_health_model == null || can(provider::azapi::parse_resource_id("Microsoft.CloudHealth/healthmodels", entity.signal_groups.embedded_health_model.resource_id))
    ])
    error_message = "Every embedded health model resource ID must identify a `Microsoft.CloudHealth/healthmodels` resource."
  }
  validation {
    condition = alltrue([
      for entity in var.entities :
      entity.signal_groups.azure_monitor_workspace == null || can(provider::azapi::parse_resource_id("Microsoft.Monitor/accounts", entity.signal_groups.azure_monitor_workspace.azure_monitor_workspace_resource_id))
    ])
    error_message = "Every Azure Monitor workspace resource ID must identify a `Microsoft.Monitor/accounts` resource."
  }
  validation {
    condition = alltrue([
      for entity in var.entities :
      entity.signal_groups.azure_log_analytics == null || can(provider::azapi::parse_resource_id("Microsoft.OperationalInsights/workspaces", entity.signal_groups.azure_log_analytics.log_analytics_workspace_resource_id))
    ])
    error_message = "Every Log Analytics workspace resource ID must identify a `Microsoft.OperationalInsights/workspaces` resource."
  }
}

variable "lock" {
  type = object({
    kind = string
    name = optional(string, null)
  })
  default     = null
  description = "Controls the resource lock configuration on the health model."

  validation {
    condition     = var.lock == null || contains(["CanNotDelete", "ReadOnly"], var.lock.kind)
    error_message = "`lock.kind` must be `CanNotDelete` or `ReadOnly`."
  }
}

variable "managed_identities" {
  type = object({
    system_assigned            = optional(bool, false)
    user_assigned_resource_ids = optional(set(string), [])
  })
  default     = {}
  description = "Controls the managed identity configuration on the health model."
  nullable    = false

  validation {
    condition = alltrue([
      for resource_id in var.managed_identities.user_assigned_resource_ids :
      can(provider::azapi::parse_resource_id("Microsoft.ManagedIdentity/userAssignedIdentities", resource_id))
    ])
    error_message = "Every user-assigned identity must be a valid `Microsoft.ManagedIdentity/userAssignedIdentities` resource ID."
  }
}

variable "relationships" {
  type = map(object({
    name               = string
    display_name       = optional(string)
    parent_entity_name = string
    child_entity_name  = string
    tags               = optional(map(string))
  }))
  default     = {}
  description = "THIS IS A VARIABLE USED FOR A PREVIEW SERVICE/FEATURE, MICROSOFT MAY NOT PROVIDE SUPPORT FOR THIS, PLEASE CHECK THE PRODUCT DOCS FOR CLARIFICATION. Entity relationships keyed by arbitrary Terraform-stable keys."
  nullable    = false
}

variable "resource_types" {
  type = object({
    cloudhealth_healthmodels       = optional(string, "Microsoft.CloudHealth/healthmodels@2026-05-01-preview")
    authorization_locks            = optional(string, "Microsoft.Authorization/locks@2020-05-01")
    authorization_role_assignments = optional(string, "Microsoft.Authorization/roleAssignments@2022-04-01")
    insights_diagnostic_settings   = optional(string, "Microsoft.Insights/diagnosticSettings@2021-05-01-preview")
    cloudhealth_healthmodels_entities = optional(object({
      cloudhealth_healthmodels_entities = optional(string)
    }), {})
    cloudhealth_healthmodels_authenticationsettings = optional(object({
      cloudhealth_healthmodels_authenticationsettings = optional(string)
    }), {})
    cloudhealth_healthmodels_signaldefinitions = optional(object({
      cloudhealth_healthmodels_signaldefinitions = optional(string)
    }), {})
    cloudhealth_healthmodels_relationships = optional(object({
      cloudhealth_healthmodels_relationships = optional(string)
    }), {})
    cloudhealth_healthmodels_discoveryrules = optional(object({
      cloudhealth_healthmodels_discoveryrules = optional(string)
    }), {})
  })
  default     = {}
  description = <<DESCRIPTION
THIS IS A VARIABLE USED FOR A PREVIEW SERVICE/FEATURE, MICROSOFT MAY NOT PROVIDE SUPPORT FOR THIS, PLEASE CHECK THE PRODUCT DOCS FOR CLARIFICATION. Override the AzAPI resource type and API version strings used by this module and its submodules.

- `cloudhealth_healthmodels` - The health model resource managed by this module.
- `authorization_locks` - The management lock applied to the health model.
- `authorization_role_assignments` - Role assignments scoped to the health model.
- `insights_diagnostic_settings` - Diagnostic settings scoped to the health model.
- `cloudhealth_healthmodels_entities` - Override slot shared by the model-named root entity convergence resource and cascaded unchanged to the entity submodule. The submodule owns its tested default; when omitted, the root convergence resource derives the matching child type from `cloudhealth_healthmodels`.
  - `cloudhealth_healthmodels_entities` - The entity resource type.
- `cloudhealth_healthmodels_authenticationsettings` - Override slot for the authentication-setting submodule.
  - `cloudhealth_healthmodels_authenticationsettings` - The authentication setting resource type.
- `cloudhealth_healthmodels_signaldefinitions` - Override slot for the signal-definition submodule.
  - `cloudhealth_healthmodels_signaldefinitions` - The signal definition resource type.
- `cloudhealth_healthmodels_relationships` - Override slot for the relationship submodule.
  - `cloudhealth_healthmodels_relationships` - The relationship resource type.
- `cloudhealth_healthmodels_discoveryrules` - Override slot for the discovery-rule submodule.
  - `cloudhealth_healthmodels_discoveryrules` - The discovery rule resource type.
DESCRIPTION
  nullable    = false
}

variable "retry" {
  type = object({
    error_message_regex  = optional(list(string), ["ScopeLocked"])
    interval_seconds     = optional(number, 15)
    max_interval_seconds = optional(number, 60)
  })
  default     = {}
  description = "Retry configuration applied to every AzAPI resource managed by this module and cascaded to submodules. By default, only `ScopeLocked` is retried at 15-second intervals up to 60 seconds so deletion can converge while Azure propagates management-lock removal."
  nullable    = false
}

variable "role_assignments" {
  type = map(object({
    role_definition_id_or_name             = string
    principal_id                           = string
    description                            = optional(string, null)
    skip_service_principal_aad_check       = optional(bool, false)
    condition                              = optional(string, null)
    condition_version                      = optional(string, null)
    delegated_managed_identity_resource_id = optional(string, null)
    principal_type                         = optional(string, null)
  }))
  default     = {}
  description = "Role assignments to create on the health model. These assignments grant access to the health model itself, not to resources monitored by its identity."
  nullable    = false
}

variable "root_entity" {
  type = object({
    display_name = optional(string)
    canvas_position = optional(object({
      x = number
      y = number
    }))
    icon = optional(object({
      icon_name   = string
      custom_data = optional(string)
    }))
    health_objective = optional(number)
    impact           = optional(string, "Standard")
    tags             = optional(map(string))
    dependencies = optional(object({
      aggregation_type    = optional(string, "WorstOf")
      degraded_threshold  = optional(number)
      unhealthy_threshold = optional(number)
      unit                = optional(string)
      ignore_unknown      = optional(bool, true)
    }), {})
    alerts = optional(object({
      degraded = optional(object({
        severity         = string
        description      = optional(string)
        action_group_ids = optional(set(string), [])
      }))
      unhealthy = optional(object({
        severity         = string
        description      = optional(string)
        action_group_ids = optional(set(string), [])
      }))
    }))
  })
  default     = {}
  description = "THIS IS A VARIABLE USED FOR A PREVIEW SERVICE/FEATURE, MICROSOFT MAY NOT PROVIDE SUPPORT FOR THIS, PLEASE CHECK THE PRODUCT DOCS FOR CLARIFICATION. Configuration for the always-managed model-named root entity."
  nullable    = false

  validation {
    condition     = contains(["Standard", "Limited", "Suppressed"], var.root_entity.impact)
    error_message = "`root_entity.impact` must be `Standard`, `Limited`, or `Suppressed`."
  }
  validation {
    condition     = contains(["WorstOf", "MinHealthy", "MaxNotHealthy"], var.root_entity.dependencies.aggregation_type)
    error_message = "`root_entity.dependencies.aggregation_type` must be `WorstOf`, `MinHealthy`, or `MaxNotHealthy`."
  }
  validation {
    condition = var.root_entity.dependencies.aggregation_type == "WorstOf" || (
      var.root_entity.dependencies.unit != null &&
      var.root_entity.dependencies.unhealthy_threshold != null
    )
    error_message = "MinHealthy and MaxNotHealthy dependency aggregation require `unit` and `unhealthy_threshold`."
  }
}

variable "signal_definitions" {
  type = map(object({
    name              = string
    display_name      = optional(string)
    signal_kind       = string
    refresh_interval  = optional(string, "PT1M")
    tags              = optional(map(string))
    data_unit         = optional(string)
    metric_namespace  = optional(string)
    metric_name       = optional(string)
    aggregation_type  = optional(string)
    dimension_filter  = optional(string)
    query_text        = optional(string)
    time_grain        = optional(string)
    value_column_name = optional(string)
    evaluation_rules = object({
      degraded_rule = optional(object({
        operator         = string
        threshold        = optional(number)
        sensitivity      = optional(string)
        look_back_window = optional(string)
      }))
      unhealthy_rule = object({
        operator         = string
        threshold        = optional(number)
        sensitivity      = optional(string)
        look_back_window = optional(string)
      })
    })
  }))
  default     = {}
  description = "THIS IS A VARIABLE USED FOR A PREVIEW SERVICE/FEATURE, MICROSOFT MAY NOT PROVIDE SUPPORT FOR THIS, PLEASE CHECK THE PRODUCT DOCS FOR CLARIFICATION. Reusable signal definitions keyed by arbitrary Terraform-stable keys."
  nullable    = false

  validation {
    condition = alltrue([
      for definition in var.signal_definitions :
      contains(["AzureResourceMetric", "PrometheusMetricsQuery", "LogAnalyticsQuery"], definition.signal_kind)
    ])
    error_message = "Every signal definition kind must be `AzureResourceMetric`, `PrometheusMetricsQuery`, or `LogAnalyticsQuery`."
  }
  validation {
    condition = alltrue([
      for definition in var.signal_definitions :
      definition.signal_kind == "AzureResourceMetric" ? (
        definition.metric_namespace != null &&
        definition.metric_name != null &&
        definition.aggregation_type != null &&
        definition.time_grain != null
        ) : (
        definition.query_text != null
      )
    ])
    error_message = "AzureResourceMetric definitions require metric_namespace, metric_name, aggregation_type, and time_grain; query definitions require query_text."
  }
  validation {
    condition = alltrue([
      for definition in var.signal_definitions :
      contains(["PT1M", "PT5M", "PT10M", "PT15M", "PT30M", "PT1H", "PT2H"], definition.refresh_interval)
    ])
    error_message = "Every signal definition refresh interval must be supported by the CloudHealth API."
  }
  validation {
    condition = alltrue(flatten([
      for definition in var.signal_definitions : [
        for rule in concat(
          definition.evaluation_rules.degraded_rule == null ? [] : [definition.evaluation_rules.degraded_rule],
          [definition.evaluation_rules.unhealthy_rule],
        ) :
        contains(["GreaterThan", "LessThan", "LessThanOrEqual", "GreaterThanOrEqual", "Equal", "NotEqual", "Dynamic"], rule.operator)
      ]
    ]))
    error_message = "Every signal evaluation operator must be supported by the CloudHealth API."
  }
  validation {
    condition = alltrue([
      for definition in var.signal_definitions :
      definition.evaluation_rules.degraded_rule == null || definition.evaluation_rules.degraded_rule.operator != "Dynamic"
    ])
    error_message = "Dynamic is valid only for an unhealthy evaluation rule."
  }
  validation {
    condition = alltrue(flatten([
      for definition in var.signal_definitions : [
        for rule in concat(
          definition.evaluation_rules.degraded_rule == null ? [] : [definition.evaluation_rules.degraded_rule],
          [definition.evaluation_rules.unhealthy_rule],
          ) : rule.operator == "Dynamic" ? (
          rule.sensitivity != null &&
          rule.look_back_window != null &&
          try(contains(["Low", "Medium", "High"], rule.sensitivity), false) &&
          try(contains(["PT5M", "PT15M", "PT30M", "PT1H"], rule.look_back_window), false)
          ) : (
          rule.sensitivity == null &&
          rule.look_back_window == null
        )
      ]
    ]))
    error_message = "Dynamic rules require `sensitivity` (`Low`, `Medium`, or `High`) and `look_back_window` (`PT5M`, `PT15M`, `PT30M`, or `PT1H`); static rules must omit both fields."
  }
}

variable "tags" {
  type        = map(string)
  default     = null
  description = "A map of tags to assign to the health model."
}

variable "timeouts" {
  type = object({
    create = optional(string)
    read   = optional(string)
    update = optional(string)
    delete = optional(string)
  })
  default     = null
  description = "Per-operation timeouts applied to AzAPI resources managed by this module."
}
