resource "azapi_resource" "this" {
  name      = var.name
  parent_id = var.parent_id
  type      = var.resource_types.cloudhealth_healthmodels_discoveryrules
  body = {
    properties = {
      addRecommendedSignals   = var.add_recommended_signals
      addResourceHealthSignal = var.add_resource_health_signal
      authenticationSetting   = var.authentication_setting
      discoverRelationships   = var.discover_relationships
      displayName             = var.display_name
      specification           = local.specification
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
}
