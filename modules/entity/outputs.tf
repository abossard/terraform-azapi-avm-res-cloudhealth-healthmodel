output "resource_id" {
  description = "The resource ID of the entity."
  value       = azapi_resource.this.id
}

output "name" {
  description = "The entity name."
  value       = azapi_resource.this.name
}

output "dependency_aggregation_type" {
  description = "The configured dependency aggregation type, when a dependency signal group is present."
  value       = try(var.signal_groups.dependencies.aggregation_type, null)
}

output "azure_resource_id" {
  description = "The Azure resource ID represented by the entity, when an Azure-resource or embedded-model signal group is present."
  value = var.signal_groups.embedded_health_model != null ? var.signal_groups.embedded_health_model.resource_id : (
    var.signal_groups.azure_resource != null ? var.signal_groups.azure_resource.azure_resource_id : null
  )
}

output "has_inline_signals" {
  description = "Whether the entity contains any inline signals."
  value       = length(local.azure_resource_signals) + length(local.prometheus_signals) + length(local.log_analytics_signals) > 0
}

output "inline_signal_counts" {
  description = "Counts of inline signals by signal group."
  value = {
    azure_resource          = length(local.azure_resource_signals)
    azure_monitor_workspace = length(local.prometheus_signals)
    azure_log_analytics     = length(local.log_analytics_signals)
  }
}
