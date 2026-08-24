module "avm_interfaces" {
  source  = "Azure/avm-utl-interfaces/azure"
  version = "0.7.0"

  diagnostic_settings = {
    for key, setting in var.diagnostic_settings :
    key => merge(setting, {
      metric_categories = setting.metric_categories == toset(["AllMetrics"]) ? [] : setting.metric_categories
    })
  }
  enable_telemetry                          = var.enable_telemetry
  lock                                      = var.lock
  managed_identities                        = var.managed_identities
  role_assignment_definition_lookup_enabled = true
  role_assignment_definition_scope          = "/subscriptions/${split("/", var.parent_id)[2]}"
  role_assignments                          = var.role_assignments
}

resource "azapi_resource" "lock" {
  count = var.lock == null ? 0 : 1

  name                   = coalesce(module.avm_interfaces.lock_azapi.name, "lock-${var.lock.kind}")
  parent_id              = azapi_resource.this.id
  type                   = var.resource_types.authorization_locks
  body                   = module.avm_interfaces.lock_azapi.body
  create_headers         = var.enable_telemetry ? { "User-Agent" = local.avm_azapi_header } : null
  delete_headers         = var.enable_telemetry ? { "User-Agent" = local.avm_azapi_header } : null
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

  depends_on = [
    azapi_resource.diagnostic_setting,
    azapi_resource.role_assignment,
    azapi_update_resource.root_entity,
    module.authentication_setting,
    module.discovery_rule,
    module.entity,
    module.relationship,
    module.signal_definition,
  ]
}

resource "azapi_resource" "role_assignment" {
  for_each = module.avm_interfaces.role_assignments_azapi

  name           = each.value.name
  parent_id      = azapi_resource.this.id
  type           = var.resource_types.authorization_role_assignments
  body           = each.value.body
  create_headers = var.enable_telemetry ? { "User-Agent" = local.avm_azapi_header } : null
  delete_headers = var.enable_telemetry ? { "User-Agent" = local.avm_azapi_header } : null
  read_headers   = var.enable_telemetry ? { "User-Agent" = local.avm_azapi_header } : null
  replace_triggers_refs = [
    "properties.principalId",
    "properties.roleDefinitionId",
    "properties.principalType",
    "properties.description",
    "properties.condition",
    "properties.conditionVersion",
    "properties.delegatedManagedIdentityResourceId",
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

resource "azapi_resource" "diagnostic_setting" {
  for_each = module.avm_interfaces.diagnostic_settings_azapi

  name                 = each.value.name
  parent_id            = azapi_resource.this.id
  type                 = var.resource_types.insights_diagnostic_settings
  body                 = each.value.body
  create_headers       = var.enable_telemetry ? { "User-Agent" = local.avm_azapi_header } : null
  delete_headers       = var.enable_telemetry ? { "User-Agent" = local.avm_azapi_header } : null
  ignore_null_property = true
  ignore_other_items_in_list = [
    "properties.logs",
    "properties.metrics",
  ]
  list_unique_id_property = {
    "properties.logs"    = "category, categoryGroup"
    "properties.metrics" = "category"
  }
  read_headers              = var.enable_telemetry ? { "User-Agent" = local.avm_azapi_header } : null
  replace_triggers_refs     = []
  response_export_values    = []
  retry                     = var.retry
  schema_validation_enabled = false
  update_headers            = var.enable_telemetry ? { "User-Agent" = local.avm_azapi_header } : null

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
