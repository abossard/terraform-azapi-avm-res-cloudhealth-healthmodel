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

resource "random_uuid" "storage_reader" {}

resource "azapi_resource" "resource_group" {
  location  = "centralus"
  name      = "rg-hm-complete-${random_string.suffix.result}"
  parent_id = local.subscription_resource_id
  type      = "Microsoft.Resources/resourceGroups@2024-11-01"
  body = {
    properties = {}
  }
  response_export_values = []
}

resource "azapi_resource" "identity" {
  location               = azapi_resource.resource_group.location
  name                   = "id-hm-${random_string.suffix.result}"
  parent_id              = azapi_resource.resource_group.id
  type                   = "Microsoft.ManagedIdentity/userAssignedIdentities@2023-01-31"
  body                   = {}
  response_export_values = ["properties.principalId"]
}

resource "azapi_resource" "storage" {
  location  = azapi_resource.resource_group.location
  name      = "sthm${random_string.suffix.result}"
  parent_id = azapi_resource.resource_group.id
  type      = "Microsoft.Storage/storageAccounts@2025-06-01"
  body = {
    kind = "StorageV2"
    properties = {
      allowBlobPublicAccess = false
      minimumTlsVersion     = "TLS1_2"
    }
    sku = {
      name = "Standard_ZRS"
    }
  }
  response_export_values = []
}

resource "azapi_resource" "workspace" {
  location  = azapi_resource.resource_group.location
  name      = "law-hm-${random_string.suffix.result}"
  parent_id = azapi_resource.resource_group.id
  type      = "Microsoft.OperationalInsights/workspaces@2025-02-01"
  body = {
    properties = {
      retentionInDays = 30
      sku = {
        name = "PerGB2018"
      }
    }
  }
  response_export_values = []
}

resource "azapi_resource" "storage_reader" {
  name      = random_uuid.storage_reader.result
  parent_id = azapi_resource.storage.id
  type      = "Microsoft.Authorization/roleAssignments@2022-04-01"
  body = {
    properties = {
      principalId      = module.health_model.system_assigned_mi_principal_id
      principalType    = "ServicePrincipal"
      roleDefinitionId = "${local.subscription_resource_id}/providers/Microsoft.Authorization/roleDefinitions/acdd72a7-3385-48ef-bd42-f606fba81ae7"
    }
  }
  response_export_values = []
}

module "health_model" {
  source = "../.."

  location  = azapi_resource.resource_group.location
  name      = "hm-complete-${random_string.suffix.result}"
  parent_id = azapi_resource.resource_group.id
  managed_identities = {
    system_assigned = true
  }
  authentication_settings = {
    monitored_resources = {
      name                  = "auth-monitored"
      display_name          = "Monitored resource identity"
      managed_identity_name = "SystemAssigned"
    }
  }
  signal_definitions = {
    availability = {
      name             = "storage-availability"
      display_name     = "Storage availability"
      signal_kind      = "AzureResourceMetric"
      data_unit        = "Percent"
      refresh_interval = "PT5M"
      metric_namespace = "Microsoft.Storage/storageAccounts"
      metric_name      = "Availability"
      aggregation_type = "Average"
      time_grain       = "PT5M"
      evaluation_rules = {
        degraded_rule = {
          operator  = "LessThan"
          threshold = 99.9
        }
        unhealthy_rule = {
          operator  = "LessThan"
          threshold = 99
        }
      }
    }
  }
  entities = {
    storage = {
      name             = "storage"
      display_name     = "Monitored storage"
      health_objective = 99.9
      alerts = {
        degraded = {
          severity    = "Sev3"
          description = "Storage is degraded."
        }
        unhealthy = {
          severity    = "Sev1"
          description = "Storage is unhealthy."
        }
      }
      signal_groups = {
        azure_resource = {
          authentication_setting = "auth-monitored"
          azure_resource_id      = azapi_resource.storage.id
          resource_health = {
            enabled = "Enabled"
          }
          signals = [
            {
              name                   = "availability"
              signal_definition_name = "storage-availability"
            },
            {
              name             = "transactions"
              display_name     = "Storage transactions"
              metric_namespace = "Microsoft.Storage/storageAccounts"
              metric_name      = "Transactions"
              aggregation_type = "Total"
              data_unit        = "Count"
              refresh_interval = "PT5M"
              time_grain       = "PT5M"
              evaluation_rules = {
                degraded_rule = {
                  operator  = "LessThan"
                  threshold = 10
                }
                unhealthy_rule = {
                  operator  = "LessThan"
                  threshold = 2
                }
              }
            }
          ]
        }
      }
    }
  }
  relationships = {
    root_storage = {
      name               = "root-storage"
      parent_entity_name = "hm-complete-${random_string.suffix.result}"
      child_entity_name  = "storage"
    }
  }
  role_assignments = {
    identity_reader = {
      role_definition_id_or_name = "Reader"
      principal_id               = azapi_resource.identity.output.properties.principalId
      principal_type             = "ServicePrincipal"
    }
  }
  diagnostic_settings = {
    workspace = {
      name                  = "send-cloudhealth-logs"
      log_categories        = []
      log_groups            = ["allLogs"]
      metric_categories     = []
      workspace_resource_id = azapi_resource.workspace.id
    }
  }
  lock = {
    kind = "CanNotDelete"
  }
  tags = {
    example = "complete"
  }
  enable_telemetry = false

}
