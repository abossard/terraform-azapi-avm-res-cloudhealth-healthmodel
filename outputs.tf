output "authentication_setting_resource_ids" {
  description = "A map of authentication setting resource IDs keyed by the caller's stable keys."
  value       = { for key, child in module.authentication_setting : key => child.resource_id }
}

output "discovery_rule_resource_ids" {
  description = "A map of discovery rule resource IDs keyed by the caller's stable keys."
  value       = { for key, child in module.discovery_rule : key => child.resource_id }
}

output "entity_resource_ids" {
  description = "A map of caller-defined entity resource IDs keyed by the caller's stable keys."
  value       = { for key, child in module.entity : key => child.resource_id }
}

output "name" {
  description = "The name of the health model."
  value       = azapi_resource.this.name
}

output "relationship_resource_ids" {
  description = "A map of relationship resource IDs keyed by the caller's stable keys."
  value       = { for key, child in module.relationship : key => child.resource_id }
}

output "resource_id" {
  description = "The resource ID of the health model."
  value       = azapi_resource.this.id
}

output "root_entity_resource_id" {
  description = "The resource ID of the model-named root entity."
  value       = azapi_update_resource.root_entity.id
}

output "signal_definition_resource_ids" {
  description = "A map of signal definition resource IDs keyed by the caller's stable keys."
  value       = { for key, child in module.signal_definition : key => child.resource_id }
}

output "system_assigned_mi_principal_id" {
  description = "The principal ID of the system-assigned managed identity, when enabled."
  value       = try(azapi_resource.this.output.identity.principalId, null)
}

output "system_assigned_mi_tenant_id" {
  description = "The tenant ID of the system-assigned managed identity, when enabled."
  value       = try(azapi_resource.this.output.identity.tenantId, null)
}
