terraform {
  required_version = ">= 1.9, < 2.0"

  required_providers {
    azapi = {
      source  = "Azure/azapi"
      version = "~> 2.4, < 3.0"
    }
    external = {
      source  = "hashicorp/external"
      version = "~> 2.3"
    }
    random = {
      source  = "hashicorp/random"
      version = "~> 3.6"
    }
  }
}

provider "azapi" {}

data "external" "subscription" {
  program = ["sh", "-c", "az account show --query id --output tsv 2>/dev/null | tail -n 1 | jq -R '{subscription_id: .}'"]
}

locals {
  subscription_resource_id = "/subscriptions/${data.external.subscription.result.subscription_id}"
}

resource "random_string" "suffix" {
  length  = 6
  lower   = true
  numeric = true
  special = false
  upper   = false
}

resource "azapi_resource" "resource_group" {
  location  = "centralus"
  name      = "rg-hm-models-${random_string.suffix.result}"
  parent_id = local.subscription_resource_id
  type      = "Microsoft.Resources/resourceGroups@2024-11-01"
  body = {
    properties = {}
  }
  response_export_values = []
}

module "child" {
  source = "../.."

  location         = azapi_resource.resource_group.location
  name             = "hm-child-${random_string.suffix.result}"
  parent_id        = azapi_resource.resource_group.id
  enable_telemetry = false
}

module "parent" {
  source = "../.."

  location  = azapi_resource.resource_group.location
  name      = "hm-parent-${random_string.suffix.result}"
  parent_id = azapi_resource.resource_group.id
  managed_identities = {
    system_assigned = true
  }
  authentication_settings = {
    system = {
      name                  = "auth-system"
      managed_identity_name = "SystemAssigned"
    }
  }
  entities = {
    embedded_child = {
      name         = "embedded-child"
      display_name = "Child health model"
      signal_groups = {
        embedded_health_model = {
          authentication_setting = "auth-system"
          resource_id            = module.child.resource_id
        }
      }
    }
  }
  relationships = {
    root_child = {
      name               = "root-child"
      parent_entity_name = "hm-parent-${random_string.suffix.result}"
      child_entity_name  = "embedded-child"
    }
  }
  enable_telemetry = false
}
