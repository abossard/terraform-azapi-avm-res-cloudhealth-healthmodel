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
  name      = "rg-hm-default-${random_string.suffix.result}"
  parent_id = local.subscription_resource_id
  type      = "Microsoft.Resources/resourceGroups@2024-11-01"
  body = {
    properties = {}
  }
  response_export_values = []
}

module "health_model" {
  source = "../.."

  location         = azapi_resource.resource_group.location
  name             = "hm-default-${random_string.suffix.result}"
  parent_id        = azapi_resource.resource_group.id
  enable_telemetry = false
}
