variable "name" {
  type        = string
  description = "THIS IS A VARIABLE USED FOR A PREVIEW SERVICE/FEATURE, MICROSOFT MAY NOT PROVIDE SUPPORT FOR THIS, PLEASE CHECK THE PRODUCT DOCS FOR CLARIFICATION. The relationship name."
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

variable "parent_entity_name" {
  type        = string
  description = "THIS IS A VARIABLE USED FOR A PREVIEW SERVICE/FEATURE, MICROSOFT MAY NOT PROVIDE SUPPORT FOR THIS, PLEASE CHECK THE PRODUCT DOCS FOR CLARIFICATION. The parent entity name."
  nullable    = false
}

variable "child_entity_name" {
  type        = string
  description = "THIS IS A VARIABLE USED FOR A PREVIEW SERVICE/FEATURE, MICROSOFT MAY NOT PROVIDE SUPPORT FOR THIS, PLEASE CHECK THE PRODUCT DOCS FOR CLARIFICATION. The child entity name."
  nullable    = false
}

variable "display_name" {
  type        = string
  default     = null
  description = "THIS IS A VARIABLE USED FOR A PREVIEW SERVICE/FEATURE, MICROSOFT MAY NOT PROVIDE SUPPORT FOR THIS, PLEASE CHECK THE PRODUCT DOCS FOR CLARIFICATION. The display name."
}

variable "tags" {
  type        = map(string)
  default     = null
  description = "THIS IS A VARIABLE USED FOR A PREVIEW SERVICE/FEATURE, MICROSOFT MAY NOT PROVIDE SUPPORT FOR THIS, PLEASE CHECK THE PRODUCT DOCS FOR CLARIFICATION. Tags stored in relationship properties."
}

variable "enable_telemetry" {
  type        = bool
  default     = true
  description = "Controls whether telemetry is enabled."
  nullable    = false
}

variable "resource_types" {
  type = object({
    cloudhealth_healthmodels_relationships = optional(string, "Microsoft.CloudHealth/healthmodels/relationships@2026-05-01-preview")
  })
  default     = {}
  nullable    = false
  description = <<DESCRIPTION
THIS IS A VARIABLE USED FOR A PREVIEW SERVICE/FEATURE, MICROSOFT MAY NOT PROVIDE SUPPORT FOR THIS, PLEASE CHECK THE PRODUCT DOCS FOR CLARIFICATION. Override the AzAPI resource type and API version used by this submodule.

- `cloudhealth_healthmodels_relationships` - The relationship resource managed by this submodule.
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
