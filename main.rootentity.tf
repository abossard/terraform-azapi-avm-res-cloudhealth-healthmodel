resource "azapi_update_resource" "root_entity" {
  resource_id = "${azapi_resource.this.id}/entities/${var.name}"
  type        = local.root_entity_resource_type
  body = {
    properties = local.root_entity_properties
  }
  locks                  = [azapi_resource.this.id]
  read_headers           = var.enable_telemetry ? { "User-Agent" : local.avm_azapi_header } : null
  response_export_values = []
  retry                  = var.retry
  update_headers         = var.enable_telemetry ? { "User-Agent" : local.avm_azapi_header } : null

  dynamic "timeouts" {
    for_each = var.timeouts == null ? {} : { this = var.timeouts }

    content {
      read   = timeouts.value.read
      update = timeouts.value.update
    }
  }
}
