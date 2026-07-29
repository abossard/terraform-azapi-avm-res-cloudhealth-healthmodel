resource "azapi_resource" "this" {
  name      = var.name
  parent_id = var.parent_id
  type      = var.resource_types.cloudhealth_healthmodels_relationships
  body = {
    properties = {
      childEntityName  = var.child_entity_name
      displayName      = var.display_name
      parentEntityName = var.parent_entity_name
      tags             = var.tags
    }
  }
  create_headers       = var.enable_telemetry ? { "User-Agent" = local.avm_azapi_header } : null
  delete_headers       = var.enable_telemetry ? { "User-Agent" = local.avm_azapi_header } : null
  ignore_null_property = true
  read_headers         = var.enable_telemetry ? { "User-Agent" = local.avm_azapi_header } : null
  replace_triggers_refs = [
    "properties.parentEntityName",
    "properties.childEntityName",
  ]
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
