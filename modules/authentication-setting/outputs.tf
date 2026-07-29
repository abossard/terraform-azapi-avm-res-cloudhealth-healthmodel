output "resource_id" {
  description = "The resource ID of the authentication setting."
  value       = azapi_resource.this.id
}

output "name" {
  description = "The authentication setting name."
  value       = azapi_resource.this.name
}
