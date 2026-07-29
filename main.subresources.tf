module "authentication_setting" {
  source   = "./modules/authentication-setting"
  for_each = var.authentication_settings

  managed_identity_name = each.value.managed_identity_name
  name                  = each.value.name
  parent_id             = azapi_resource.this.id
  display_name          = each.value.display_name
  enable_telemetry      = var.enable_telemetry
  resource_types        = var.resource_types.cloudhealth_healthmodels_authenticationsettings
  retry                 = var.retry
  timeouts              = var.timeouts
}

module "signal_definition" {
  source   = "./modules/signal-definition"
  for_each = var.signal_definitions

  evaluation_rules  = each.value.evaluation_rules
  name              = each.value.name
  parent_id         = azapi_resource.this.id
  signal_kind       = each.value.signal_kind
  aggregation_type  = each.value.aggregation_type
  data_unit         = each.value.data_unit
  dimension_filter  = each.value.dimension_filter
  display_name      = each.value.display_name
  enable_telemetry  = var.enable_telemetry
  metric_name       = each.value.metric_name
  metric_namespace  = each.value.metric_namespace
  query_text        = each.value.query_text
  refresh_interval  = each.value.refresh_interval
  resource_types    = var.resource_types.cloudhealth_healthmodels_signaldefinitions
  retry             = var.retry
  tags              = each.value.tags
  time_grain        = each.value.time_grain
  timeouts          = var.timeouts
  value_column_name = each.value.value_column_name
}

module "entity" {
  source   = "./modules/entity"
  for_each = var.entities

  name             = each.value.name
  parent_id        = azapi_resource.this.id
  alerts           = each.value.alerts
  canvas_position  = each.value.canvas_position
  display_name     = each.value.display_name
  enable_telemetry = var.enable_telemetry
  health_objective = each.value.health_objective
  icon             = each.value.icon
  impact           = each.value.impact
  resource_types   = var.resource_types.cloudhealth_healthmodels_entities
  retry            = var.retry
  signal_groups    = each.value.signal_groups
  tags             = each.value.tags
  timeouts         = var.timeouts

  depends_on = [
    module.authentication_setting,
    module.signal_definition,
  ]
}

module "relationship" {
  source   = "./modules/relationship"
  for_each = var.relationships

  child_entity_name  = each.value.child_entity_name
  name               = each.value.name
  parent_entity_name = each.value.parent_entity_name
  parent_id          = azapi_resource.this.id
  display_name       = each.value.display_name
  enable_telemetry   = var.enable_telemetry
  resource_types     = var.resource_types.cloudhealth_healthmodels_relationships
  retry              = var.retry
  tags               = each.value.tags
  timeouts           = var.timeouts

  depends_on = [
    module.discovery_rule,
    module.entity,
    azapi_update_resource.root_entity,
  ]
}

module "discovery_rule" {
  source   = "./modules/discovery-rule"
  for_each = var.discovery_rules

  add_recommended_signals    = each.value.add_recommended_signals
  authentication_setting     = each.value.authentication_setting
  discover_relationships     = each.value.discover_relationships
  name                       = each.value.name
  parent_id                  = azapi_resource.this.id
  specification              = each.value.specification
  add_resource_health_signal = each.value.add_resource_health_signal
  display_name               = each.value.display_name
  enable_telemetry           = var.enable_telemetry
  resource_types             = var.resource_types.cloudhealth_healthmodels_discoveryrules
  retry                      = var.retry
  timeouts                   = var.timeouts

  depends_on = [
    module.authentication_setting,
  ]
}
