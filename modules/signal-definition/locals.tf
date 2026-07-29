locals {
  degraded_rule = var.evaluation_rules.degraded_rule == null ? null : {
    lookBackWindow = var.evaluation_rules.degraded_rule.look_back_window
    operator       = var.evaluation_rules.degraded_rule.operator
    sensitivity    = var.evaluation_rules.degraded_rule.sensitivity
    threshold      = var.evaluation_rules.degraded_rule.threshold
  }
  unhealthy_rule = {
    lookBackWindow = var.evaluation_rules.unhealthy_rule.look_back_window
    operator       = var.evaluation_rules.unhealthy_rule.operator
    sensitivity    = var.evaluation_rules.unhealthy_rule.sensitivity
    threshold      = var.evaluation_rules.unhealthy_rule.threshold
  }
  properties = merge(
    {
      dataUnit    = var.data_unit
      displayName = var.display_name
      evaluationRules = {
        degradedRule  = local.degraded_rule
        unhealthyRule = local.unhealthy_rule
      }
      refreshInterval = var.refresh_interval
      signalKind      = var.signal_kind
      tags            = var.tags
    },
    var.signal_kind == "AzureResourceMetric" ? {
      aggregationType = var.aggregation_type
      dimensionFilter = var.dimension_filter
      metricName      = var.metric_name
      metricNamespace = var.metric_namespace
      timeGrain       = var.time_grain
    } : {},
    var.signal_kind == "PrometheusMetricsQuery" ? {
      queryText = var.query_text
      timeGrain = var.time_grain
    } : {},
    var.signal_kind == "LogAnalyticsQuery" ? {
      queryText       = var.query_text
      timeGrain       = var.time_grain
      valueColumnName = var.value_column_name
    } : {},
  )
}
