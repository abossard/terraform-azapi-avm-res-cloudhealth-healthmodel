provider "azapi" {}
provider "modtm" {}
provider "random" {}

run "setup" {
  module {
    source = "./tests/setup/relationship-replacement"
  }

  variables {
    location = "centralus"
  }
}

run "initial_relationship" {
  module {
    source = "./modules/relationship"
  }

  variables {
    child_entity_name  = run.setup.child_entity_names[0]
    enable_telemetry   = false
    name               = "root-child"
    parent_entity_name = run.setup.health_model_name
    parent_id          = run.setup.health_model_id
  }
}

run "endpoint_change_replaces_relationship" {
  command = plan

  module {
    source = "./modules/relationship"
  }

  variables {
    child_entity_name  = run.setup.child_entity_names[1]
    enable_telemetry   = false
    name               = "root-child"
    parent_entity_name = run.setup.health_model_name
    parent_id          = run.setup.health_model_id
  }

  assert {
    condition = toset(azapi_resource.this.replace_triggers_refs) == toset([
      "properties.parentEntityName",
      "properties.childEntityName",
    ])
    error_message = "The real-provider plan must carry both immutable endpoint replacement references."
  }
}
