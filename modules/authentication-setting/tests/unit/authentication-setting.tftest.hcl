mock_provider "azapi" {}
mock_provider "modtm" {}
mock_provider "random" {}

variables {
  enable_telemetry      = false
  name                  = "auth-system"
  parent_id             = "/subscriptions/00000000-0000-0000-0000-000000000000/resourceGroups/rg-health/providers/Microsoft.CloudHealth/healthmodels/hm-test"
  managed_identity_name = "SystemAssigned"
}

run "managed_identity_authentication" {
  command = apply

  variables {
    resource_types = {
      cloudhealth_healthmodels_authenticationsettings = "Microsoft.CloudHealth/healthModels/authenticationSettings@2026-05-01-preview"
    }
  }

  assert {
    condition     = length([azapi_resource.this]) == 1 && azapi_resource.this.body.properties.authenticationKind == "ManagedIdentity"
    error_message = "The submodule must create one managed identity authentication setting."
  }

  assert {
    condition     = azapi_resource.this.type == "Microsoft.CloudHealth/healthModels/authenticationSettings@2026-05-01-preview"
    error_message = "The authentication-setting resource type override must use its deterministic ARM-derived key."
  }

  assert {
    condition     = contains(try(azapi_resource.this.retry.error_message_regex, []), "ScopeLocked")
    error_message = "The submodule must retry only the lock-removal propagation error by default."
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
