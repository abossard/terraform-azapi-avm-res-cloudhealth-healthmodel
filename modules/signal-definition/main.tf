resource "azapi_resource" "this" {
  name      = var.name
  parent_id = var.parent_id
  type      = var.resource_types.cloudhealth_healthmodels_signaldefinitions
  body = {
    properties = local.properties
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
      condition = var.signal_kind == "AzureResourceMetric" ? (
        var.metric_namespace != null &&
        var.metric_name != null &&
        var.aggregation_type != null &&
        var.time_grain != null
        ) : (
        var.query_text != null
      )
      error_message = "AzureResourceMetric requires metric_namespace, metric_name, aggregation_type, and time_grain; query kinds require query_text."
    }
  }
}
