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
  name      = "rg-hm-role-${random_string.suffix.result}"
  parent_id = "/subscriptions/${data.azapi_client_config.current.subscription_id}"
  type      = "Microsoft.Resources/resourceGroups@2024-11-01"
  body      = {}

  response_export_values = []
}

resource "azapi_resource" "identity" {
  for_each = toset(["principal-a", "principal-b"])

  location  = var.location
  name      = "${each.value}-${random_string.suffix.result}"
  parent_id = azapi_resource.resource_group.id
  type      = "Microsoft.ManagedIdentity/userAssignedIdentities@2023-01-31"
  body      = {}

  response_export_values = ["properties.principalId"]
}
