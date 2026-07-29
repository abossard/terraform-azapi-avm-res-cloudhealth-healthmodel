data "azapi_client_config" "current" {}

resource "random_string" "suffix" {
  length  = 6
  lower   = true
  numeric = true
  special = false
  upper   = false
}

resource "azapi_resource" "resource_group" {
  location  = var.location
  name      = "rg-hm-rel-${random_string.suffix.result}"
  parent_id = "/subscriptions/${data.azapi_client_config.current.subscription_id}"
  type      = "Microsoft.Resources/resourceGroups@2024-11-01"
  body      = {}

  response_export_values = []
}

resource "azapi_resource" "health_model" {
  location  = var.location
  name      = "hm-rel-${random_string.suffix.result}"
  parent_id = azapi_resource.resource_group.id
  type      = "Microsoft.CloudHealth/healthmodels@2026-05-01-preview"
  body = {
    properties = {}
  }
  identity {
    type = "SystemAssigned"
  }

  response_export_values = []
}

resource "azapi_resource" "entity" {
  for_each = toset(["child-a", "child-b"])

  name      = each.value
  parent_id = azapi_resource.health_model.id
  type      = "Microsoft.CloudHealth/healthmodels/entities@2026-05-01-preview"
  body = {
    properties = {
      displayName = each.value
      impact      = "Standard"
      signalGroups = {
        dependencies = {
          aggregationType = "WorstOf"
          ignoreUnknown   = true
        }
      }
    }
  }

  response_export_values = []
}
