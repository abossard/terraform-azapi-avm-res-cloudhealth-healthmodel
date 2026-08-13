variable "name" {
  type        = string
  description = "THIS IS A VARIABLE USED FOR A PREVIEW SERVICE/FEATURE, MICROSOFT MAY NOT PROVIDE SUPPORT FOR THIS, PLEASE CHECK THE PRODUCT DOCS FOR CLARIFICATION. The signal definition name."
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

variable "signal_kind" {
  type        = string
  description = "THIS IS A VARIABLE USED FOR A PREVIEW SERVICE/FEATURE, MICROSOFT MAY NOT PROVIDE SUPPORT FOR THIS, PLEASE CHECK THE PRODUCT DOCS FOR CLARIFICATION. The signal kind."
  nullable    = false

  validation {
    condition     = contains(["AzureResourceMetric", "PrometheusMetricsQuery", "LogAnalyticsQuery"], var.signal_kind)
    error_message = "`signal_kind` must be `AzureResourceMetric`, `PrometheusMetricsQuery`, or `LogAnalyticsQuery`."
  }
}

variable "evaluation_rules" {
  type = object({
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
  description = "THIS IS A VARIABLE USED FOR A PREVIEW SERVICE/FEATURE, MICROSOFT MAY NOT PROVIDE SUPPORT FOR THIS, PLEASE CHECK THE PRODUCT DOCS FOR CLARIFICATION. Static or dynamic degraded and unhealthy evaluation rules. `look_back_window` is scheduled for removal in a future CloudHealth API version."
  nullable    = false

  validation {
    condition = alltrue([
      for rule in concat(
        var.evaluation_rules.degraded_rule == null ? [] : [var.evaluation_rules.degraded_rule],
        [var.evaluation_rules.unhealthy_rule],
      ) : contains(["GreaterThan", "LessThan", "LessThanOrEqual", "GreaterThanOrEqual", "Equal", "NotEqual", "Dynamic"], rule.operator)
    ])
    error_message = "Every evaluation operator must be supported by the CloudHealth API."
  }
  validation {
    condition     = var.evaluation_rules.degraded_rule == null || var.evaluation_rules.degraded_rule.operator != "Dynamic"
    error_message = "Dynamic is valid only for an unhealthy evaluation rule."
  }
  validation {
    condition = alltrue([
      for rule in concat(
        var.evaluation_rules.degraded_rule == null ? [] : [var.evaluation_rules.degraded_rule],
        [var.evaluation_rules.unhealthy_rule],
        ) : rule.operator == "Dynamic" ? (
        rule.sensitivity != null &&
        rule.look_back_window != null &&
        try(contains(["Low", "Medium", "High"], rule.sensitivity), false) &&
        try(contains(["PT5M", "PT15M", "PT30M", "PT1H"], rule.look_back_window), false)
        ) : (
        rule.sensitivity == null &&
        rule.look_back_window == null
      )
    ])
    error_message = "Dynamic rules require `sensitivity` (`Low`, `Medium`, or `High`) and `look_back_window` (`PT5M`, `PT15M`, `PT30M`, or `PT1H`); static rules must omit both fields."
  }
}

variable "display_name" {
  type        = string
  default     = null
  description = "THIS IS A VARIABLE USED FOR A PREVIEW SERVICE/FEATURE, MICROSOFT MAY NOT PROVIDE SUPPORT FOR THIS, PLEASE CHECK THE PRODUCT DOCS FOR CLARIFICATION. The display name."
}

variable "refresh_interval" {
  type        = string
  default     = "PT1M"
  description = "THIS IS A VARIABLE USED FOR A PREVIEW SERVICE/FEATURE, MICROSOFT MAY NOT PROVIDE SUPPORT FOR THIS, PLEASE CHECK THE PRODUCT DOCS FOR CLARIFICATION. The signal evaluation interval."

  validation {
    condition     = contains(["PT1M", "PT5M", "PT10M", "PT15M", "PT30M", "PT1H", "PT2H"], var.refresh_interval)
    error_message = "`refresh_interval` must be supported by the CloudHealth API."
  }
}

variable "tags" {
  type        = map(string)
  default     = null
  description = "THIS IS A VARIABLE USED FOR A PREVIEW SERVICE/FEATURE, MICROSOFT MAY NOT PROVIDE SUPPORT FOR THIS, PLEASE CHECK THE PRODUCT DOCS FOR CLARIFICATION. Tags stored in signal definition properties."
}

variable "data_unit" {
  type        = string
  default     = null
  description = "THIS IS A VARIABLE USED FOR A PREVIEW SERVICE/FEATURE, MICROSOFT MAY NOT PROVIDE SUPPORT FOR THIS, PLEASE CHECK THE PRODUCT DOCS FOR CLARIFICATION. The signal result unit."
}

variable "metric_namespace" {
  type        = string
  default     = null
  description = "THIS IS A VARIABLE USED FOR A PREVIEW SERVICE/FEATURE, MICROSOFT MAY NOT PROVIDE SUPPORT FOR THIS, PLEASE CHECK THE PRODUCT DOCS FOR CLARIFICATION. The Azure metric namespace."
}

variable "metric_name" {
  type        = string
  default     = null
  description = "THIS IS A VARIABLE USED FOR A PREVIEW SERVICE/FEATURE, MICROSOFT MAY NOT PROVIDE SUPPORT FOR THIS, PLEASE CHECK THE PRODUCT DOCS FOR CLARIFICATION. The Azure metric name."
}

variable "aggregation_type" {
  type        = string
  default     = null
  description = "THIS IS A VARIABLE USED FOR A PREVIEW SERVICE/FEATURE, MICROSOFT MAY NOT PROVIDE SUPPORT FOR THIS, PLEASE CHECK THE PRODUCT DOCS FOR CLARIFICATION. The Azure metric aggregation type."

  validation {
    condition     = var.aggregation_type == null || contains(["None", "Average", "Count", "Minimum", "Maximum", "Total"], var.aggregation_type)
    error_message = "`aggregation_type` must be supported by the CloudHealth API."
  }
}

variable "dimension_filter" {
  type        = string
  default     = null
  description = "THIS IS A VARIABLE USED FOR A PREVIEW SERVICE/FEATURE, MICROSOFT MAY NOT PROVIDE SUPPORT FOR THIS, PLEASE CHECK THE PRODUCT DOCS FOR CLARIFICATION. An optional Azure metric dimension filter."
}

variable "query_text" {
  type        = string
  default     = null
  description = "THIS IS A VARIABLE USED FOR A PREVIEW SERVICE/FEATURE, MICROSOFT MAY NOT PROVIDE SUPPORT FOR THIS, PLEASE CHECK THE PRODUCT DOCS FOR CLARIFICATION. PromQL or KQL query text."
}

variable "time_grain" {
  type        = string
  default     = null
  description = "THIS IS A VARIABLE USED FOR A PREVIEW SERVICE/FEATURE, MICROSOFT MAY NOT PROVIDE SUPPORT FOR THIS, PLEASE CHECK THE PRODUCT DOCS FOR CLARIFICATION. The signal time grain."
}

variable "value_column_name" {
  type        = string
  default     = null
  description = "THIS IS A VARIABLE USED FOR A PREVIEW SERVICE/FEATURE, MICROSOFT MAY NOT PROVIDE SUPPORT FOR THIS, PLEASE CHECK THE PRODUCT DOCS FOR CLARIFICATION. The numeric KQL result column to evaluate."
}

variable "enable_telemetry" {
  type        = bool
  default     = true
  description = "Controls whether telemetry is enabled."
  nullable    = false
}

variable "resource_types" {
  type = object({
    cloudhealth_healthmodels_signaldefinitions = optional(string, "Microsoft.CloudHealth/healthmodels/signaldefinitions@2026-05-01-preview")
  })
  default     = {}
  nullable    = false
  description = <<DESCRIPTION
THIS IS A VARIABLE USED FOR A PREVIEW SERVICE/FEATURE, MICROSOFT MAY NOT PROVIDE SUPPORT FOR THIS, PLEASE CHECK THE PRODUCT DOCS FOR CLARIFICATION. Override the AzAPI resource type and API version used by this submodule.

- `cloudhealth_healthmodels_signaldefinitions` - The signal definition resource managed by this submodule.
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
