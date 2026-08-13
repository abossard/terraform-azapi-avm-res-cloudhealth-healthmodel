resource "azapi_resource" "this" {
  location  = var.location
  name      = var.name
  parent_id = var.parent_id
  type      = var.resource_types.cloudhealth_healthmodels
  body = {
    properties = {}
  }
  create_headers         = var.enable_telemetry ? { "User-Agent" = local.avm_azapi_header } : null
  delete_headers         = var.enable_telemetry ? { "User-Agent" = local.avm_azapi_header } : null
  read_headers           = var.enable_telemetry ? { "User-Agent" = local.avm_azapi_header } : null
  replace_triggers_refs  = []
  response_export_values = ["identity.principalId", "identity.tenantId"]
  retry                  = var.retry
  tags                   = var.tags
  update_headers         = var.enable_telemetry ? { "User-Agent" = local.avm_azapi_header } : null

  dynamic "identity" {
    for_each = local.managed_identity == null ? {} : { this = local.managed_identity }

    content {
      identity_ids = identity.value.identity_ids
      type         = identity.value.type
    }
  }

  dynamic "timeouts" {
    for_each = var.timeouts == null ? {} : { this = var.timeouts }

    content {
      create = timeouts.value.create
      delete = timeouts.value.delete
      read   = timeouts.value.read
      update = timeouts.value.update
    }
  }

  lifecycle {
    precondition {
      condition     = local.relationship_endpoints_valid
      error_message = "Every relationship endpoint must resolve to the model-named root or a declared entity."
    }

    precondition {
      condition     = local.authentication_references_valid
      error_message = "Every entity signal group and discovery rule authentication reference must resolve to a declared authentication setting."
    }

    precondition {
      condition     = local.signal_definition_references_valid
      error_message = "Every reusable signal reference must resolve to a declared signal definition."
    }

    precondition {
      condition     = local.authentication_identities_attached
      error_message = "Every authentication setting identity must be attached to the health model."
    }

    precondition {
      condition     = local.child_names_unique
      error_message = "Explicit ARM child names must be unique within each child resource type."
    }

    precondition {
      condition     = local.inline_evaluation_operators_valid
      error_message = "Every inline signal evaluation operator must be `GreaterThan`, `LessThan`, `LessThanOrEqual`, `GreaterThanOrEqual`, `Equal`, `NotEqual`, or `Dynamic`."
    }

    precondition {
      condition     = local.inline_dynamic_evaluation_rules_valid
      error_message = "Dynamic is valid only for an unhealthy rule and requires `sensitivity` (`Low`, `Medium`, or `High`) plus `look_back_window` (`PT5M`, `PT15M`, `PT30M`, or `PT1H`); static rules must omit both fields."
    }

    precondition {
      condition     = local.inline_dynamic_signal_kinds_valid
      error_message = "Dynamic thresholds are supported only on Azure resource metric signals, so an inline Dynamic rule must sit in the `azure_resource` signal group."
    }

    precondition {
      condition     = local.dynamic_rules_exclude_degraded_valid
      error_message = "A Dynamic unhealthy rule cannot be combined with a degraded rule on the same signal."
    }

    precondition {
      condition     = local.signal_cadence_valid
      error_message = "Every signal `refresh_interval` must be less than or equal to its `time_grain`."
    }

    precondition {
      condition     = local.dynamic_time_grains_valid
      error_message = "A signal evaluated with a Dynamic unhealthy rule requires a `time_grain` of `PT5M` or longer."
    }
  }
}
