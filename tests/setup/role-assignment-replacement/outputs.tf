output "health_model_name" {
  description = "The health model name used by the public-boundary lifecycle test."
  value       = "hm-role-${random_string.suffix.result}"
}

output "principal_ids" {
  description = "The two real managed-identity principal IDs used by the lifecycle test."
  value       = sort([for identity in azapi_resource.identity : identity.output.properties.principalId])
}

output "reader_role_definition_id" {
  description = "The subscription-scoped built-in Reader role definition ID."
  value       = "/subscriptions/${data.azapi_client_config.current.subscription_id}/providers/Microsoft.Authorization/roleDefinitions/acdd72a7-3385-48ef-bd42-f606fba81ae7"
}

output "resource_group_id" {
  description = "The task-specific resource group ID."
  value       = azapi_resource.resource_group.id
}
