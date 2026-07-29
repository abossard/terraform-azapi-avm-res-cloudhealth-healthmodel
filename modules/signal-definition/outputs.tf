output "resource_id" {
  description = "The resource ID of the signal definition."
  value       = azapi_resource.this.id
}

output "name" {
  description = "The signal definition name."
  value       = azapi_resource.this.name
}
