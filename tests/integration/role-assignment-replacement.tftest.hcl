provider "azapi" {}
provider "modtm" {}
provider "random" {}

run "setup" {
  module {
    source = "./tests/setup/role-assignment-replacement"
  }

  variables {
    location = "centralus"
  }
}

run "initial_role_assignment" {
  variables {
    enable_telemetry = false
    location         = "centralus"
    managed_identities = {
      system_assigned = true
    }
    name      = run.setup.health_model_name
    parent_id = run.setup.resource_group_id
    role_assignments = {
      reader = {
        principal_id               = run.setup.principal_ids[0]
        principal_type             = "ServicePrincipal"
        role_definition_id_or_name = run.setup.reader_role_definition_id
      }
    }
  }

  assert {
    condition     = azapi_resource.role_assignment["reader"].body.properties.principalId == run.setup.principal_ids[0]
    error_message = "The initial public-boundary apply must create the role assignment for the first principal."
  }
}

run "principal_change_replaces_role_assignment" {
  command = plan

  variables {
    enable_telemetry = false
    location         = "centralus"
    managed_identities = {
      system_assigned = true
    }
    name      = run.setup.health_model_name
    parent_id = run.setup.resource_group_id
    role_assignments = {
      reader = {
        principal_id               = run.setup.principal_ids[1]
        principal_type             = "ServicePrincipal"
        role_definition_id_or_name = run.setup.reader_role_definition_id
      }
    }
  }

  assert {
    condition = toset(azapi_resource.role_assignment["reader"].replace_triggers_refs) == toset([
      "properties.principalId",
      "properties.roleDefinitionId",
      "properties.principalType",
      "properties.description",
      "properties.condition",
      "properties.conditionVersion",
      "properties.delegatedManagedIdentityResourceId",
    ])
    error_message = "The role assignment must carry every immutable body path so a same-name principal change plans replacement."
  }
}

run "description_change_replaces_role_assignment" {
  command = plan

  variables {
    enable_telemetry = false
    location         = "centralus"
    managed_identities = {
      system_assigned = true
    }
    name      = run.setup.health_model_name
    parent_id = run.setup.resource_group_id
    role_assignments = {
      reader = {
        description                = "replacement probe"
        principal_id               = run.setup.principal_ids[0]
        principal_type             = "ServicePrincipal"
        role_definition_id_or_name = run.setup.reader_role_definition_id
      }
    }
  }

  assert {
    condition     = azapi_resource.role_assignment["reader"].body.properties.description == "replacement probe"
    error_message = "The optional immutable description mutation must reach the real-provider plan."
  }
}
