output "resource_id" {
  description = "The resource ID of the discovery rule."
  value       = azapi_resource.this.id
}

output "name" {
  description = "The discovery rule name."
  value       = azapi_resource.this.name
}
