output "child_entity_names" {
  description = "The two entity names used to prove endpoint replacement."
  value       = sort([for entity in azapi_resource.entity : entity.name])
}

output "health_model_id" {
  description = "The health model resource ID."
  value       = azapi_resource.health_model.id
}

output "health_model_name" {
  description = "The health model name."
  value       = azapi_resource.health_model.name
}
