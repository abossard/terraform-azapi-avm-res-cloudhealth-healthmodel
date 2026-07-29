locals {
  specification = merge(
    { kind = var.specification.kind },
    var.specification.kind == "ResourceGraphQuery" ? {
      resourceGraphQuery = var.specification.resource_graph_query
    } : {},
    var.specification.kind == "ApplicationInsightsTopology" ? {
      applicationInsightsResourceId = var.specification.application_insights_resource_id
    } : {},
  )
}
