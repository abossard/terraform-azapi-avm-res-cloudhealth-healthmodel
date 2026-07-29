mock_provider "azapi" {}
mock_provider "modtm" {}
mock_provider "random" {}

variables {
  enable_telemetry   = false
  name               = "root-child"
  parent_id          = "/subscriptions/00000000-0000-0000-0000-000000000000/resourceGroups/rg-health/providers/Microsoft.CloudHealth/healthmodels/hm-test"
  parent_entity_name = "hm-test"
  child_entity_name  = "child"
}

run "entity_relationship" {
  command = apply

  variables {
    resource_types = {
      cloudhealth_healthmodels_relationships = "Microsoft.CloudHealth/healthModels/relationships@2026-05-01-preview"
    }
  }

  assert {
    condition     = length([azapi_resource.this]) == 1 && azapi_resource.this.body.properties.childEntityName == "child"
    error_message = "The submodule must create one entity relationship."
  }

  assert {
    condition     = azapi_resource.this.type == "Microsoft.CloudHealth/healthModels/relationships@2026-05-01-preview"
    error_message = "The relationship resource type override must use its deterministic ARM-derived key."
  }

  assert {
    condition     = contains(try(azapi_resource.this.retry.error_message_regex, []), "ScopeLocked")
    error_message = "The submodule must retry only the lock-removal propagation error by default."
  }
}

run "endpoint_change_replaces_relationship" {
  command = plan

  variables {
    child_entity_name = "other-child"
    resource_types = {
      cloudhealth_healthmodels_relationships = "Microsoft.CloudHealth/healthModels/relationships@2026-05-01-preview"
    }
  }

  assert {
    condition = toset(azapi_resource.this.replace_triggers_refs) == toset([
      "properties.parentEntityName",
      "properties.childEntityName",
    ])
    error_message = "Changing either immutable relationship endpoint must replace the relationship."
  }
}

run "invalid_parent" {
  command = plan

  variables {
    parent_id = "/subscriptions/invalid"
  }

  expect_failures = [
    var.parent_id,
  ]
}
