output "resource_id" {
  description = "The resource ID of the relationship."
  value       = azapi_resource.this.id
}

output "name" {
  description = "The relationship name."
  value       = azapi_resource.this.name
}
