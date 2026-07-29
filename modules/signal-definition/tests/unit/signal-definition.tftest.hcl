mock_provider "azapi" {}
mock_provider "modtm" {}
mock_provider "random" {}

variables {
  enable_telemetry = false
  name             = "metric-availability"
  parent_id        = "/subscriptions/00000000-0000-0000-0000-000000000000/resourceGroups/rg-health/providers/Microsoft.CloudHealth/healthmodels/hm-test"
  signal_kind      = "AzureResourceMetric"
  metric_namespace = "Microsoft.Storage/storageAccounts"
  metric_name      = "Availability"
  aggregation_type = "Average"
  time_grain       = "PT5M"
  evaluation_rules = {
    unhealthy_rule = {
      operator  = "LessThan"
      threshold = 99
    }
  }
}

run "metric_definition" {
  command = apply

  variables {
    resource_types = {
      cloudhealth_healthmodels_signaldefinitions = "Microsoft.CloudHealth/healthModels/signalDefinitions@2026-05-01-preview"
    }
  }

  assert {
    condition     = length([azapi_resource.this]) == 1 && azapi_resource.this.body.properties.metricName == "Availability"
    error_message = "The submodule must create one Azure metric signal definition."
  }

  assert {
    condition     = azapi_resource.this.type == "Microsoft.CloudHealth/healthModels/signalDefinitions@2026-05-01-preview"
    error_message = "The signal-definition resource type override must use its deterministic ARM-derived key."
  }

  assert {
    condition     = contains(try(azapi_resource.this.retry.error_message_regex, []), "ScopeLocked")
    error_message = "The submodule must retry only the lock-removal propagation error by default."
  }
}

run "missing_metric_name" {
  command = plan

  variables {
    metric_name = null
  }

  expect_failures = [
    azapi_resource.this,
  ]
}

run "dynamic_unhealthy_rule" {
  command = apply

  variables {
    evaluation_rules = {
      unhealthy_rule = {
        operator         = "Dynamic"
        sensitivity      = "High"
        look_back_window = "PT30M"
      }
    }
  }

  assert {
    condition = (
      azapi_resource.this.body.properties.evaluationRules.unhealthyRule.operator == "Dynamic" &&
      azapi_resource.this.body.properties.evaluationRules.unhealthyRule.sensitivity == "High" &&
      azapi_resource.this.body.properties.evaluationRules.unhealthyRule.lookBackWindow == "PT30M"
    )
    error_message = "A valid unhealthy Dynamic rule must preserve its documented sensitivity and look-back window."
  }
}

run "dynamic_rule_missing_configuration" {
  command = plan

  variables {
    evaluation_rules = {
      unhealthy_rule = {
        operator = "Dynamic"
      }
    }
  }

  expect_failures = [
    var.evaluation_rules,
  ]
}

run "degraded_dynamic_rule" {
  command = plan

  variables {
    evaluation_rules = {
      degraded_rule = {
        operator = "Dynamic"
      }
      unhealthy_rule = {
        operator  = "LessThan"
        threshold = 99
      }
    }
  }

  expect_failures = [
    var.evaluation_rules,
  ]
}

run "static_rule_rejects_dynamic_fields" {
  command = plan

  variables {
    evaluation_rules = {
      unhealthy_rule = {
        operator         = "LessThan"
        threshold        = 99
        sensitivity      = "High"
        look_back_window = "PT30M"
      }
    }
  }

  expect_failures = [
    var.evaluation_rules,
  ]
}

run "invalid_dynamic_rule_enums" {
  command = plan

  variables {
    evaluation_rules = {
      unhealthy_rule = {
        operator         = "Dynamic"
        sensitivity      = "Extreme"
        look_back_window = "PT2H"
      }
    }
  }

  expect_failures = [
    var.evaluation_rules,
  ]
}
