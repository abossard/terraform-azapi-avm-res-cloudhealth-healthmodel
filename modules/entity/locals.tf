locals {
  azure_resource_signals = flatten([
    for group in var.signal_groups.azure_resource[*] : [
      for signal in group.signals : merge(
        {
          name       = signal.name
          signalKind = "AzureResourceMetric"
        },
        signal.signal_definition_name == null ? {} : { signalDefinitionName = signal.signal_definition_name },
        signal.display_name == null ? {} : { displayName = signal.display_name },
        signal.metric_namespace == null ? {} : { metricNamespace = signal.metric_namespace },
        signal.metric_name == null ? {} : { metricName = signal.metric_name },
        signal.aggregation_type == null ? {} : { aggregationType = signal.aggregation_type },
        signal.dimension_filter == null ? {} : { dimensionFilter = signal.dimension_filter },
        signal.data_unit == null ? {} : { dataUnit = signal.data_unit },
        signal.refresh_interval == null ? {} : { refreshInterval = signal.refresh_interval },
        signal.time_grain == null ? {} : { timeGrain = signal.time_grain },
        signal.evaluation_rules == null ? {} : {
          evaluationRules = merge(
            signal.evaluation_rules.degraded_rule == null ? {} : {
              degradedRule = {
                lookBackWindow = signal.evaluation_rules.degraded_rule.look_back_window
                operator       = signal.evaluation_rules.degraded_rule.operator
                sensitivity    = signal.evaluation_rules.degraded_rule.sensitivity
                threshold      = signal.evaluation_rules.degraded_rule.threshold
              }
            },
            {
              unhealthyRule = {
                lookBackWindow = signal.evaluation_rules.unhealthy_rule.look_back_window
                operator       = signal.evaluation_rules.unhealthy_rule.operator
                sensitivity    = signal.evaluation_rules.unhealthy_rule.sensitivity
                threshold      = signal.evaluation_rules.unhealthy_rule.threshold
              }
            },
          )
        },
      )
    ]
  ])
  prometheus_signals = flatten([
    for group in var.signal_groups.azure_monitor_workspace[*] : [
      for signal in group.signals : merge(
        {
          name       = signal.name
          signalKind = "PrometheusMetricsQuery"
        },
        signal.signal_definition_name == null ? {} : { signalDefinitionName = signal.signal_definition_name },
        signal.display_name == null ? {} : { displayName = signal.display_name },
        signal.query_text == null ? {} : { queryText = signal.query_text },
        signal.data_unit == null ? {} : { dataUnit = signal.data_unit },
        signal.refresh_interval == null ? {} : { refreshInterval = signal.refresh_interval },
        signal.time_grain == null ? {} : { timeGrain = signal.time_grain },
        signal.evaluation_rules == null ? {} : {
          evaluationRules = merge(
            signal.evaluation_rules.degraded_rule == null ? {} : {
              degradedRule = {
                lookBackWindow = signal.evaluation_rules.degraded_rule.look_back_window
                operator       = signal.evaluation_rules.degraded_rule.operator
                sensitivity    = signal.evaluation_rules.degraded_rule.sensitivity
                threshold      = signal.evaluation_rules.degraded_rule.threshold
              }
            },
            {
              unhealthyRule = {
                lookBackWindow = signal.evaluation_rules.unhealthy_rule.look_back_window
                operator       = signal.evaluation_rules.unhealthy_rule.operator
                sensitivity    = signal.evaluation_rules.unhealthy_rule.sensitivity
                threshold      = signal.evaluation_rules.unhealthy_rule.threshold
              }
            },
          )
        },
      )
    ]
  ])
  log_analytics_signals = flatten([
    for group in var.signal_groups.azure_log_analytics[*] : [
      for signal in group.signals : merge(
        {
          name       = signal.name
          signalKind = "LogAnalyticsQuery"
        },
        signal.signal_definition_name == null ? {} : { signalDefinitionName = signal.signal_definition_name },
        signal.display_name == null ? {} : { displayName = signal.display_name },
        signal.query_text == null ? {} : { queryText = signal.query_text },
        signal.data_unit == null ? {} : { dataUnit = signal.data_unit },
        signal.refresh_interval == null ? {} : { refreshInterval = signal.refresh_interval },
        signal.time_grain == null ? {} : { timeGrain = signal.time_grain },
        signal.value_column_name == null ? {} : { valueColumnName = signal.value_column_name },
        signal.evaluation_rules == null ? {} : {
          evaluationRules = merge(
            signal.evaluation_rules.degraded_rule == null ? {} : {
              degradedRule = {
                lookBackWindow = signal.evaluation_rules.degraded_rule.look_back_window
                operator       = signal.evaluation_rules.degraded_rule.operator
                sensitivity    = signal.evaluation_rules.degraded_rule.sensitivity
                threshold      = signal.evaluation_rules.degraded_rule.threshold
              }
            },
            {
              unhealthyRule = {
                lookBackWindow = signal.evaluation_rules.unhealthy_rule.look_back_window
                operator       = signal.evaluation_rules.unhealthy_rule.operator
                sensitivity    = signal.evaluation_rules.unhealthy_rule.sensitivity
                threshold      = signal.evaluation_rules.unhealthy_rule.threshold
              }
            },
          )
        },
      )
    ]
  ])
  azure_resource_signal_group = merge(
    var.signal_groups.embedded_health_model == null ? {} : {
      authenticationSetting = var.signal_groups.embedded_health_model.authentication_setting
      azureResourceId       = var.signal_groups.embedded_health_model.resource_id
    },
    var.signal_groups.azure_resource == null ? {} : {
      authenticationSetting = var.signal_groups.azure_resource.authentication_setting
      azureResourceId       = var.signal_groups.azure_resource.azure_resource_id
    },
    var.signal_groups.azure_resource == null || var.signal_groups.azure_resource.azure_resource_kind == null ? {} : {
      azureResourceKind = var.signal_groups.azure_resource.azure_resource_kind
    },
    var.signal_groups.azure_resource == null || var.signal_groups.azure_resource.resource_health == null ? {} : {
      resourceHealth = {
        enabled = var.signal_groups.azure_resource.resource_health.enabled
      }
    },
    length(local.azure_resource_signals) == 0 ? {} : { signals = local.azure_resource_signals },
  )
  signal_groups = merge(
    length(keys(local.azure_resource_signal_group)) == 0 ? {} : {
      azureResource = local.azure_resource_signal_group
    },
    var.signal_groups.azure_monitor_workspace == null ? {} : {
      azureMonitorWorkspace = merge(
        {
          authenticationSetting           = var.signal_groups.azure_monitor_workspace.authentication_setting
          azureMonitorWorkspaceResourceId = var.signal_groups.azure_monitor_workspace.azure_monitor_workspace_resource_id
        },
        length(local.prometheus_signals) == 0 ? {} : { signals = local.prometheus_signals },
      )
    },
    var.signal_groups.azure_log_analytics == null ? {} : {
      azureLogAnalytics = merge(
        {
          authenticationSetting           = var.signal_groups.azure_log_analytics.authentication_setting
          logAnalyticsWorkspaceResourceId = var.signal_groups.azure_log_analytics.log_analytics_workspace_resource_id
        },
        length(local.log_analytics_signals) == 0 ? {} : { signals = local.log_analytics_signals },
      )
    },
    var.signal_groups.dependencies == null ? {} : {
      dependencies = {
        aggregationType    = var.signal_groups.dependencies.aggregation_type
        degradedThreshold  = var.signal_groups.dependencies.degraded_threshold
        ignoreUnknown      = var.signal_groups.dependencies.ignore_unknown
        unhealthyThreshold = var.signal_groups.dependencies.unhealthy_threshold
        unit               = var.signal_groups.dependencies.unit
      }
    },
  )
  alerts = var.alerts == null ? null : {
    degraded = var.alerts.degraded == null ? null : merge(
      { severity = var.alerts.degraded.severity },
      var.alerts.degraded.description == null ? {} : { description = var.alerts.degraded.description },
      length(var.alerts.degraded.action_group_ids) == 0 ? {} : { actionGroupIds = var.alerts.degraded.action_group_ids },
    )
    unhealthy = var.alerts.unhealthy == null ? null : merge(
      { severity = var.alerts.unhealthy.severity },
      var.alerts.unhealthy.description == null ? {} : { description = var.alerts.unhealthy.description },
      length(var.alerts.unhealthy.action_group_ids) == 0 ? {} : { actionGroupIds = var.alerts.unhealthy.action_group_ids },
    )
  }
  inline_evaluation_rules = concat(
    flatten([
      for group in var.signal_groups.azure_resource[*] : flatten([
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
      for group in var.signal_groups.azure_monitor_workspace[*] : flatten([
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
      for group in var.signal_groups.azure_log_analytics[*] : flatten([
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
