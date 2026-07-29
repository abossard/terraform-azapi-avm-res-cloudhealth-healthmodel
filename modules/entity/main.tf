resource "azapi_resource" "this" {
  name      = var.name
  parent_id = var.parent_id
  type      = var.resource_types.cloudhealth_healthmodels_entities
  body = {
    properties = {
      alerts = local.alerts
      canvasPosition = var.canvas_position == null ? null : {
        x = var.canvas_position.x
        y = var.canvas_position.y
      }
      displayName     = var.display_name
      healthObjective = var.health_objective
      icon = var.icon == null ? null : {
        customData = var.icon.custom_data
        iconName   = var.icon.icon_name
      }
      impact       = var.impact
      signalGroups = length(keys(local.signal_groups)) == 0 ? null : local.signal_groups
      tags         = var.tags
    }
  }
  create_headers         = var.enable_telemetry ? { "User-Agent" = local.avm_azapi_header } : null
  delete_headers         = var.enable_telemetry ? { "User-Agent" = local.avm_azapi_header } : null
  ignore_null_property   = true
  read_headers           = var.enable_telemetry ? { "User-Agent" = local.avm_azapi_header } : null
  replace_triggers_refs  = []
  response_export_values = []
  retry                  = var.retry
  update_headers         = var.enable_telemetry ? { "User-Agent" = local.avm_azapi_header } : null

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
      condition     = local.inline_evaluation_operators_valid
      error_message = "Every inline signal evaluation operator must be `GreaterThan`, `LessThan`, `LessThanOrEqual`, `GreaterThanOrEqual`, `Equal`, `NotEqual`, or `Dynamic`."
    }

    precondition {
      condition     = local.inline_dynamic_evaluation_rules_valid
      error_message = "Dynamic is valid only for an unhealthy rule and requires `sensitivity` (`Low`, `Medium`, or `High`) plus `look_back_window` (`PT5M`, `PT15M`, `PT30M`, or `PT1H`); static rules must omit both fields."
    }
  }
}
