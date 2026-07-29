provider "azapi" {}
provider "modtm" {}
provider "random" {}

variables {
  enable_telemetry = false
  location         = "centralus"
  name             = "hm-discovery-topology"
  parent_id        = "/subscriptions/00000000-0000-0000-0000-000000000000/resourceGroups/rg-health"
  managed_identities = {
    system_assigned = true
  }
  authentication_settings = {
    system = {
      name                  = "auth-system"
      managed_identity_name = "SystemAssigned"
    }
  }
  discovery_rules = {
    storage = {
      name                    = "discover-storage"
      authentication_setting  = "auth-system"
      discover_relationships  = "Disabled"
      add_recommended_signals = "Enabled"
      specification = {
        kind                 = "ResourceGraphQuery"
        resource_graph_query = "resources | where type =~ 'microsoft.storage/storageaccounts' | project id"
      }
    }
  }
  relationships = {
    root_discovery = {
      name               = "root-discovery"
      parent_entity_name = "hm-discovery-topology"
      child_entity_name  = "discover-storage"
    }
  }
}

run "relationship_to_discovery_entity" {
  command = plan

  assert {
    condition = (
      length(output.discovery_rule_resource_ids) == 1 &&
      length(output.relationship_resource_ids) == 1
    )
    error_message = "The public real-provider plan must accept the deterministic discovery entity as an endpoint."
  }
}
