variable "name" {
  type        = string
  description = "THIS IS A VARIABLE USED FOR A PREVIEW SERVICE/FEATURE, MICROSOFT MAY NOT PROVIDE SUPPORT FOR THIS, PLEASE CHECK THE PRODUCT DOCS FOR CLARIFICATION. The entity name."
  nullable    = false

  validation {
    condition     = can(regex("^[a-zA-Z0-9][a-zA-Z0-9-]{1,258}[a-zA-Z0-9]$", var.name))
    error_message = "`name` must be 3-260 alphanumeric or hyphen characters and start and end with an alphanumeric character."
  }
}

variable "parent_id" {
  type        = string
  description = "THIS IS A VARIABLE USED FOR A PREVIEW SERVICE/FEATURE, MICROSOFT MAY NOT PROVIDE SUPPORT FOR THIS, PLEASE CHECK THE PRODUCT DOCS FOR CLARIFICATION. The parent health model resource ID."
  nullable    = false

  validation {
    condition     = can(provider::azapi::parse_resource_id("Microsoft.CloudHealth/healthmodels", var.parent_id))
    error_message = "`parent_id` must be a valid CloudHealth health model resource ID."
  }
}

variable "display_name" {
  type        = string
  default     = null
  description = "THIS IS A VARIABLE USED FOR A PREVIEW SERVICE/FEATURE, MICROSOFT MAY NOT PROVIDE SUPPORT FOR THIS, PLEASE CHECK THE PRODUCT DOCS FOR CLARIFICATION. The display name."
}

variable "canvas_position" {
  type = object({
    x = number
    y = number
  })
  default     = null
  description = "THIS IS A VARIABLE USED FOR A PREVIEW SERVICE/FEATURE, MICROSOFT MAY NOT PROVIDE SUPPORT FOR THIS, PLEASE CHECK THE PRODUCT DOCS FOR CLARIFICATION. The entity canvas coordinates."
}

variable "icon" {
  type = object({
    icon_name   = string
    custom_data = optional(string)
  })
  default     = null
  description = "THIS IS A VARIABLE USED FOR A PREVIEW SERVICE/FEATURE, MICROSOFT MAY NOT PROVIDE SUPPORT FOR THIS, PLEASE CHECK THE PRODUCT DOCS FOR CLARIFICATION. The built-in or custom entity icon."
}

variable "health_objective" {
  type        = number
  default     = null
  description = "THIS IS A VARIABLE USED FOR A PREVIEW SERVICE/FEATURE, MICROSOFT MAY NOT PROVIDE SUPPORT FOR THIS, PLEASE CHECK THE PRODUCT DOCS FOR CLARIFICATION. The health objective percentage."

  validation {
    condition     = var.health_objective == null || (var.health_objective >= 0 && var.health_objective <= 100)
    error_message = "`health_objective` must be between 0 and 100."
  }
}

variable "impact" {
  type        = string
  default     = "Standard"
  description = "THIS IS A VARIABLE USED FOR A PREVIEW SERVICE/FEATURE, MICROSOFT MAY NOT PROVIDE SUPPORT FOR THIS, PLEASE CHECK THE PRODUCT DOCS FOR CLARIFICATION. The entity impact on health propagation."

  validation {
    condition     = contains(["Standard", "Limited", "Suppressed"], var.impact)
    error_message = "`impact` must be `Standard`, `Limited`, or `Suppressed`."
  }
}

variable "tags" {
  type        = map(string)
  default     = null
  description = "THIS IS A VARIABLE USED FOR A PREVIEW SERVICE/FEATURE, MICROSOFT MAY NOT PROVIDE SUPPORT FOR THIS, PLEASE CHECK THE PRODUCT DOCS FOR CLARIFICATION. Tags stored in entity properties."
}

variable "alerts" {
  type = object({
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
  })
  default     = null
  description = "THIS IS A VARIABLE USED FOR A PREVIEW SERVICE/FEATURE, MICROSOFT MAY NOT PROVIDE SUPPORT FOR THIS, PLEASE CHECK THE PRODUCT DOCS FOR CLARIFICATION. Degraded and unhealthy alert configuration."

  validation {
    condition = var.alerts == null || alltrue([
      for alert in concat(
        var.alerts.degraded == null ? [] : [var.alerts.degraded],
        var.alerts.unhealthy == null ? [] : [var.alerts.unhealthy],
      ) : contains(["Sev0", "Sev1", "Sev2", "Sev3", "Sev4"], alert.severity)
    ])
    error_message = "Alert severity must be `Sev0`, `Sev1`, `Sev2`, `Sev3`, or `Sev4`."
  }

  validation {
    condition = var.alerts == null || alltrue(flatten([
      for alert in concat(
        var.alerts.degraded == null ? [] : [var.alerts.degraded],
        var.alerts.unhealthy == null ? [] : [var.alerts.unhealthy],
        ) : [
        for resource_id in alert.action_group_ids :
        can(provider::azapi::parse_resource_id("Microsoft.Insights/actionGroups", resource_id))
      ]
    ]))
    error_message = "Every alert action group ID must identify a `Microsoft.Insights/actionGroups` resource."
  }
}

variable "signal_groups" {
  type = object({
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
  })
  default     = {}
  description = "THIS IS A VARIABLE USED FOR A PREVIEW SERVICE/FEATURE, MICROSOFT MAY NOT PROVIDE SUPPORT FOR THIS, PLEASE CHECK THE PRODUCT DOCS FOR CLARIFICATION. Azure metric, embedded model, PromQL, KQL, and dependency signal groups."
  nullable    = false

  validation {
    condition     = !(var.signal_groups.azure_resource != null && var.signal_groups.embedded_health_model != null)
    error_message = "`azure_resource` and `embedded_health_model` cannot both be configured."
  }

  validation {
    condition     = var.signal_groups.embedded_health_model == null || can(provider::azapi::parse_resource_id("Microsoft.CloudHealth/healthmodels", var.signal_groups.embedded_health_model.resource_id))
    error_message = "`embedded_health_model.resource_id` must identify a `Microsoft.CloudHealth/healthmodels` resource."
  }

  validation {
    condition     = var.signal_groups.azure_monitor_workspace == null || can(provider::azapi::parse_resource_id("Microsoft.Monitor/accounts", var.signal_groups.azure_monitor_workspace.azure_monitor_workspace_resource_id))
    error_message = "`azure_monitor_workspace_resource_id` must identify a `Microsoft.Monitor/accounts` resource."
  }

  validation {
    condition     = var.signal_groups.azure_log_analytics == null || can(provider::azapi::parse_resource_id("Microsoft.OperationalInsights/workspaces", var.signal_groups.azure_log_analytics.log_analytics_workspace_resource_id))
    error_message = "`log_analytics_workspace_resource_id` must identify a `Microsoft.OperationalInsights/workspaces` resource."
  }

  validation {
    condition     = var.signal_groups.azure_resource == null || var.signal_groups.azure_resource.resource_health == null || contains(["Enabled", "Disabled"], var.signal_groups.azure_resource.resource_health.enabled)
    error_message = "Resource Health `enabled` must be `Enabled` or `Disabled`."
  }

  validation {
    condition = var.signal_groups.dependencies == null || (
      contains(["WorstOf", "MinHealthy", "MaxNotHealthy"], var.signal_groups.dependencies.aggregation_type) &&
      (var.signal_groups.dependencies.unit == null || contains(["Absolute", "Percentage"], var.signal_groups.dependencies.unit))
    )
    error_message = "Dependency aggregation type or unit is invalid."
  }

  validation {
    condition = var.signal_groups.dependencies == null || var.signal_groups.dependencies.aggregation_type == "WorstOf" || (
      var.signal_groups.dependencies.unit != null &&
      var.signal_groups.dependencies.unhealthy_threshold != null
    )
    error_message = "MinHealthy and MaxNotHealthy dependency aggregation require `unit` and `unhealthy_threshold`."
  }

  validation {
    condition = var.signal_groups.azure_resource == null || alltrue([
      for signal in var.signal_groups.azure_resource.signals :
      signal.signal_definition_name != null || (
        signal.metric_namespace != null &&
        signal.metric_name != null &&
        signal.aggregation_type != null &&
        signal.time_grain != null &&
        signal.evaluation_rules != null
      )
    ])
    error_message = "Inline Azure metric signals require metric namespace, metric name, aggregation type, time grain, and evaluation rules."
  }

  validation {
    condition = var.signal_groups.azure_monitor_workspace == null || alltrue([
      for signal in var.signal_groups.azure_monitor_workspace.signals :
      signal.signal_definition_name != null || (signal.query_text != null && signal.evaluation_rules != null)
    ])
    error_message = "Inline PromQL signals require query text and evaluation rules."
  }

  validation {
    condition = var.signal_groups.azure_log_analytics == null || alltrue([
      for signal in var.signal_groups.azure_log_analytics.signals :
      signal.signal_definition_name != null || (signal.query_text != null && signal.evaluation_rules != null)
    ])
    error_message = "Inline KQL signals require query text and evaluation rules."
  }
}

variable "enable_telemetry" {
  type        = bool
  default     = true
  description = "Controls whether telemetry is enabled."
  nullable    = false
}

variable "resource_types" {
  type = object({
    cloudhealth_healthmodels_entities = optional(string, "Microsoft.CloudHealth/healthmodels/entities@2026-05-01-preview")
  })
  default     = {}
  nullable    = false
  description = <<DESCRIPTION
THIS IS A VARIABLE USED FOR A PREVIEW SERVICE/FEATURE, MICROSOFT MAY NOT PROVIDE SUPPORT FOR THIS, PLEASE CHECK THE PRODUCT DOCS FOR CLARIFICATION. Override the AzAPI resource type and API version used by this submodule.

- `cloudhealth_healthmodels_entities` - The entity resource managed by this submodule.
DESCRIPTION
}

variable "retry" {
  type = object({
    error_message_regex  = optional(list(string), ["ScopeLocked"])
    interval_seconds     = optional(number, 15)
    max_interval_seconds = optional(number, 60)
  })
  default     = {}
  description = "Retry configuration applied to the AzAPI resource. By default, only `ScopeLocked` is retried at 15-second intervals up to 60 seconds while Azure propagates management-lock removal."
  nullable    = false
}

variable "timeouts" {
  type = object({
    create = optional(string)
    read   = optional(string)
    update = optional(string)
    delete = optional(string)
  })
  default     = null
  description = "Per-operation timeouts applied to the AzAPI resource."
}
