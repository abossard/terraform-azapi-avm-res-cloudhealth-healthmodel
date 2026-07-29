variable "name" {
  type        = string
  description = "THIS IS A VARIABLE USED FOR A PREVIEW SERVICE/FEATURE, MICROSOFT MAY NOT PROVIDE SUPPORT FOR THIS, PLEASE CHECK THE PRODUCT DOCS FOR CLARIFICATION. The discovery rule name."
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

variable "authentication_setting" {
  type        = string
  description = "THIS IS A VARIABLE USED FOR A PREVIEW SERVICE/FEATURE, MICROSOFT MAY NOT PROVIDE SUPPORT FOR THIS, PLEASE CHECK THE PRODUCT DOCS FOR CLARIFICATION. The authentication setting name used by the discovery rule."
  nullable    = false
}

variable "discover_relationships" {
  type        = string
  description = "THIS IS A VARIABLE USED FOR A PREVIEW SERVICE/FEATURE, MICROSOFT MAY NOT PROVIDE SUPPORT FOR THIS, PLEASE CHECK THE PRODUCT DOCS FOR CLARIFICATION. Whether relationship discovery is enabled."
  nullable    = false

  validation {
    condition     = contains(["Enabled", "Disabled"], var.discover_relationships)
    error_message = "`discover_relationships` must be `Enabled` or `Disabled`."
  }
}

variable "add_recommended_signals" {
  type        = string
  description = "THIS IS A VARIABLE USED FOR A PREVIEW SERVICE/FEATURE, MICROSOFT MAY NOT PROVIDE SUPPORT FOR THIS, PLEASE CHECK THE PRODUCT DOCS FOR CLARIFICATION. Whether recommended signals are added."
  nullable    = false

  validation {
    condition     = contains(["Enabled", "Disabled"], var.add_recommended_signals)
    error_message = "`add_recommended_signals` must be `Enabled` or `Disabled`."
  }
}

variable "specification" {
  type = object({
    kind                             = string
    resource_graph_query             = optional(string)
    application_insights_resource_id = optional(string)
  })
  description = "THIS IS A VARIABLE USED FOR A PREVIEW SERVICE/FEATURE, MICROSOFT MAY NOT PROVIDE SUPPORT FOR THIS, PLEASE CHECK THE PRODUCT DOCS FOR CLARIFICATION. A Resource Graph query or Application Insights topology specification."
  nullable    = false

  validation {
    condition = var.specification.kind == "ResourceGraphQuery" ? (
      var.specification.resource_graph_query != null &&
      var.specification.application_insights_resource_id == null
      ) : var.specification.kind == "ApplicationInsightsTopology" ? (
      var.specification.application_insights_resource_id != null &&
      var.specification.resource_graph_query == null
    ) : false
    error_message = "ResourceGraphQuery requires only `resource_graph_query`; ApplicationInsightsTopology requires only `application_insights_resource_id`."
  }

  validation {
    condition     = var.specification.application_insights_resource_id == null || can(provider::azapi::parse_resource_id("Microsoft.Insights/components", var.specification.application_insights_resource_id))
    error_message = "`application_insights_resource_id` must identify a `Microsoft.Insights/components` resource."
  }
}

variable "display_name" {
  type        = string
  default     = null
  description = "THIS IS A VARIABLE USED FOR A PREVIEW SERVICE/FEATURE, MICROSOFT MAY NOT PROVIDE SUPPORT FOR THIS, PLEASE CHECK THE PRODUCT DOCS FOR CLARIFICATION. The display name."
}

variable "add_resource_health_signal" {
  type        = string
  default     = null
  description = "THIS IS A VARIABLE USED FOR A PREVIEW SERVICE/FEATURE, MICROSOFT MAY NOT PROVIDE SUPPORT FOR THIS, PLEASE CHECK THE PRODUCT DOCS FOR CLARIFICATION. Whether Resource Health signals are added."

  validation {
    condition     = var.add_resource_health_signal == null || contains(["Enabled", "Disabled"], var.add_resource_health_signal)
    error_message = "`add_resource_health_signal` must be `Enabled` or `Disabled`."
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
    cloudhealth_healthmodels_discoveryrules = optional(string, "Microsoft.CloudHealth/healthmodels/discoveryrules@2026-05-01-preview")
  })
  default     = {}
  nullable    = false
  description = <<DESCRIPTION
THIS IS A VARIABLE USED FOR A PREVIEW SERVICE/FEATURE, MICROSOFT MAY NOT PROVIDE SUPPORT FOR THIS, PLEASE CHECK THE PRODUCT DOCS FOR CLARIFICATION. Override the AzAPI resource type and API version used by this submodule.

- `cloudhealth_healthmodels_discoveryrules` - The discovery rule resource managed by this submodule.
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
