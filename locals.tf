locals {
  root_entity_resource_type = coalesce(
    var.resource_types.cloudhealth_healthmodels_entities.cloudhealth_healthmodels_entities,
    replace(var.resource_types.cloudhealth_healthmodels, "@", "/entities@"),
  )
  root_entity_alerts = merge(
    var.root_entity.alerts == null || var.root_entity.alerts.degraded == null ? {} : {
      degraded = merge(
        { severity = var.root_entity.alerts.degraded.severity },
        var.root_entity.alerts.degraded.description == null ? {} : { description = var.root_entity.alerts.degraded.description },
        length(var.root_entity.alerts.degraded.action_group_ids) == 0 ? {} : { actionGroupIds = var.root_entity.alerts.degraded.action_group_ids },
      )
    },
    var.root_entity.alerts == null || var.root_entity.alerts.unhealthy == null ? {} : {
      unhealthy = merge(
        { severity = var.root_entity.alerts.unhealthy.severity },
        var.root_entity.alerts.unhealthy.description == null ? {} : { description = var.root_entity.alerts.unhealthy.description },
        length(var.root_entity.alerts.unhealthy.action_group_ids) == 0 ? {} : { actionGroupIds = var.root_entity.alerts.unhealthy.action_group_ids },
      )
    },
  )
  root_entity_dependencies = merge(
    {
      aggregationType = var.root_entity.dependencies.aggregation_type
      ignoreUnknown   = var.root_entity.dependencies.ignore_unknown
    },
    var.root_entity.dependencies.degraded_threshold == null ? {} : { degradedThreshold = var.root_entity.dependencies.degraded_threshold },
    var.root_entity.dependencies.unhealthy_threshold == null ? {} : { unhealthyThreshold = var.root_entity.dependencies.unhealthy_threshold },
    var.root_entity.dependencies.unit == null ? {} : { unit = var.root_entity.dependencies.unit },
  )
  root_entity_properties = merge(
    {
      displayName = coalesce(var.root_entity.display_name, var.name)
      impact      = var.root_entity.impact
      signalGroups = {
        dependencies = local.root_entity_dependencies
      }
    },
    var.root_entity.canvas_position == null ? {} : {
      canvasPosition = {
        x = var.root_entity.canvas_position.x
        y = var.root_entity.canvas_position.y
      }
    },
    var.root_entity.icon == null ? {} : {
      icon = merge(
        { iconName = var.root_entity.icon.icon_name },
        var.root_entity.icon.custom_data == null ? {} : { customData = var.root_entity.icon.custom_data },
      )
    },
    var.root_entity.health_objective == null ? {} : { healthObjective = var.root_entity.health_objective },
    var.root_entity.tags == null ? {} : { tags = var.root_entity.tags },
    length(keys(local.root_entity_alerts)) == 0 ? {} : { alerts = local.root_entity_alerts },
  )
  managed_identity = var.managed_identities.system_assigned || length(var.managed_identities.user_assigned_resource_ids) > 0 ? {
    type = var.managed_identities.system_assigned && length(var.managed_identities.user_assigned_resource_ids) > 0 ? "SystemAssigned, UserAssigned" : (
      var.managed_identities.system_assigned ? "SystemAssigned" : "UserAssigned"
    )
    identity_ids = sort(tolist(var.managed_identities.user_assigned_resource_ids))
  } : null
  authentication_setting_names = toset([
    for setting in var.authentication_settings : setting.name
  ])
  signal_definition_names = toset([
    for definition in var.signal_definitions : definition.name
  ])
  entity_names = toset(concat(
    [var.name],
    [for entity in var.entities : entity.name],
  ))
  discovery_entity_names = toset([
    for rule in var.discovery_rules : rule.name
  ])
  relationship_endpoint_names = setunion(
    local.entity_names,
    local.discovery_entity_names,
  )
  entity_authentication_references = flatten([
    for entity in var.entities : compact([
      entity.signal_groups.azure_resource == null ? null : entity.signal_groups.azure_resource.authentication_setting,
      entity.signal_groups.embedded_health_model == null ? null : entity.signal_groups.embedded_health_model.authentication_setting,
      entity.signal_groups.azure_monitor_workspace == null ? null : entity.signal_groups.azure_monitor_workspace.authentication_setting,
      entity.signal_groups.azure_log_analytics == null ? null : entity.signal_groups.azure_log_analytics.authentication_setting,
    ])
  ])
  authentication_references = concat(
    local.entity_authentication_references,
    [for rule in var.discovery_rules : rule.authentication_setting],
  )
  signal_definition_references = flatten(concat(
    [
      for entity in var.entities : entity.signal_groups.azure_resource == null ? [] : compact([
        for signal in entity.signal_groups.azure_resource.signals : signal.signal_definition_name
      ])
    ],
    [
      for entity in var.entities : entity.signal_groups.azure_monitor_workspace == null ? [] : compact([
        for signal in entity.signal_groups.azure_monitor_workspace.signals : signal.signal_definition_name
      ])
    ],
    [
      for entity in var.entities : entity.signal_groups.azure_log_analytics == null ? [] : compact([
        for signal in entity.signal_groups.azure_log_analytics.signals : signal.signal_definition_name
      ])
    ],
  ))
  attached_user_assigned_identity_ids = toset([
    for resource_id in var.managed_identities.user_assigned_resource_ids : lower(resource_id)
  ])
  relationship_endpoints_valid = alltrue([
    for relationship in var.relationships :
    contains(local.relationship_endpoint_names, relationship.parent_entity_name) &&
    contains(local.relationship_endpoint_names, relationship.child_entity_name)
  ])
  authentication_references_valid = alltrue([
    for name in local.authentication_references :
    contains(local.authentication_setting_names, name)
  ])
  signal_definition_references_valid = alltrue([
    for name in local.signal_definition_references :
    contains(local.signal_definition_names, name)
  ])
  authentication_identities_attached = alltrue([
    for setting in var.authentication_settings :
    setting.managed_identity_name == "SystemAssigned" ? var.managed_identities.system_assigned : contains(
      local.attached_user_assigned_identity_ids,
      lower(setting.managed_identity_name),
    )
  ])
  child_names_unique = (
    length(local.authentication_setting_names) == length(var.authentication_settings) &&
    length(local.signal_definition_names) == length(var.signal_definitions) &&
    length(local.entity_names) == length(var.entities) + 1 &&
    length(toset([for relationship in var.relationships : relationship.name])) == length(var.relationships) &&
    length(toset([for rule in var.discovery_rules : rule.name])) == length(var.discovery_rules)
  )
  inline_evaluation_rules = flatten([
    for entity in var.entities : concat(
      flatten([
        for group in entity.signal_groups.azure_resource[*] : flatten([
          for signal in group.signals : signal.evaluation_rules == null ? [] : concat(
            signal.evaluation_rules.degraded_rule == null ? [] : [{
              is_unhealthy = false
              rule         = signal.evaluation_rules.degraded_rule
            }],
            [{
              is_unhealthy = true
              rule         = signal.evaluation_rules.unhealthy_rule
            }],
          )
        ])
      ]),
      flatten([
        for group in entity.signal_groups.azure_monitor_workspace[*] : flatten([
          for signal in group.signals : signal.evaluation_rules == null ? [] : concat(
            signal.evaluation_rules.degraded_rule == null ? [] : [{
              is_unhealthy = false
              rule         = signal.evaluation_rules.degraded_rule
            }],
            [{
              is_unhealthy = true
              rule         = signal.evaluation_rules.unhealthy_rule
            }],
          )
        ])
      ]),
      flatten([
        for group in entity.signal_groups.azure_log_analytics[*] : flatten([
          for signal in group.signals : signal.evaluation_rules == null ? [] : concat(
            signal.evaluation_rules.degraded_rule == null ? [] : [{
              is_unhealthy = false
              rule         = signal.evaluation_rules.degraded_rule
            }],
            [{
              is_unhealthy = true
              rule         = signal.evaluation_rules.unhealthy_rule
            }],
          )
        ])
      ]),
    )
  ])
  inline_evaluation_operators_valid = alltrue([
    for evaluation in local.inline_evaluation_rules :
    contains(["GreaterThan", "LessThan", "LessThanOrEqual", "GreaterThanOrEqual", "Equal", "NotEqual", "Dynamic"], evaluation.rule.operator)
  ])
  inline_dynamic_evaluation_rules_valid = alltrue([
    for evaluation in local.inline_evaluation_rules :
    evaluation.rule.operator == "Dynamic" ? (
      evaluation.is_unhealthy &&
      evaluation.rule.sensitivity != null &&
      evaluation.rule.look_back_window != null &&
      try(contains(["Low", "Medium", "High"], evaluation.rule.sensitivity), false) &&
      try(contains(["PT5M", "PT15M", "PT30M", "PT1H"], evaluation.rule.look_back_window), false)
      ) : (
      evaluation.rule.sensitivity == null &&
      evaluation.rule.look_back_window == null
    )
  ])
}
