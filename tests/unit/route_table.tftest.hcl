mock_provider "azapi" {
  mock_resource "azapi_resource" {
    defaults = {
      id = "/subscriptions/00000000-0000-0000-0000-000000000000/resourceGroups/test-rg/providers/Microsoft.Network/routeTables/test-rt/providers/Microsoft.Resources/mocked/mocked"
    }
  }
  mock_data "azapi_client_config" {
    defaults = {
      object_id                = "11111111-1111-1111-1111-111111111111"
      subscription_id          = "00000000-0000-0000-0000-000000000000"
      subscription_resource_id = "/subscriptions/00000000-0000-0000-0000-000000000000"
      tenant_id                = "00000000-0000-0000-0000-000000000001"
    }
  }
  mock_data "azapi_resource_list" {
    defaults = {
      output = {
        results = [
          {
            id        = "/subscriptions/00000000-0000-0000-0000-000000000000/providers/Microsoft.Authorization/roleDefinitions/acdd72a7-3385-48ef-bd42-f606fba81ae7"
            role_name = "Reader"
          }
        ]
      }
    }
  }
}

mock_provider "random" {}

mock_provider "time" {}

variables {
  enable_telemetry = false
  location         = "westeurope"
  name             = "test-rt"
  parent_id        = "/subscriptions/00000000-0000-0000-0000-000000000000/resourceGroups/test-rg"
}

override_resource {
  target = azapi_resource.this
  values = {
    id = "/subscriptions/00000000-0000-0000-0000-000000000000/resourceGroups/test-rg/providers/Microsoft.Network/routeTables/test-rt"
    output = {
      properties = {
        routes = [
          {
            name = "to-nva"
            properties = {
              addressPrefix    = "10.1.0.0/16"
              nextHopIpAddress = "10.0.0.4"
              nextHopType      = "VirtualAppliance"
            }
          },
          {
            name = "local"
            properties = {
              addressPrefix = "10.2.0.0/16"
              nextHopType   = "VnetLocal"
            }
          },
        ]
        subnets = [
          { id = "/subscriptions/00000000-0000-0000-0000-000000000000/resourceGroups/test-rg/providers/Microsoft.Network/virtualNetworks/test-vnet/subnets/snet1" },
        ]
      }
    }
  }
}

run "defaults" {
  command = apply

  assert {
    condition     = azapi_resource.this.type == "Microsoft.Network/routeTables@2025-01-01" && azapi_resource.this.parent_id == "/subscriptions/00000000-0000-0000-0000-000000000000/resourceGroups/test-rg"
    error_message = "The route table should use the default API version and parent_id."
  }
  assert {
    condition     = azapi_resource.this.body.properties.disableBgpRoutePropagation == false && length(azapi_resource.this.body.properties.routes) == 0
    error_message = "BGP route propagation should be enabled by default, and routes should only be sent as an empty placeholder."
  }
  assert {
    condition     = length(azapi_resource.lock) == 0 && length(time_sleep.lock_removal) == 0 && length(azapi_resource.role_assignments) == 0 && length(azapi_resource.legacy_routes) == 0 && length(module.routes) == 0
    error_message = "No lock, pause, role assignment or route should be created by default."
  }
  assert {
    condition     = output.resource_id == azapi_resource.this.id && output.name == "test-rt" && length(output.routes) == 0
    error_message = "The discrete outputs should describe the route table."
  }
  assert {
    condition     = output.resource.resource_group_name == "test-rg" && output.resource.bgp_route_propagation_enabled && length(output.resource.tags) == 0
    error_message = "The resource output should keep the AzureRM attribute names and empty values."
  }
  assert {
    condition     = output.resource.route[0].name == "to-nva" && output.resource.route[0].next_hop_in_ip_address == "10.0.0.4" && output.resource.route[1].next_hop_in_ip_address == "" && output.resource.route[1].next_hop_type == "VnetLocal"
    error_message = "The resource output should list the routes Azure returned, with an empty next hop address when there is none."
  }
  assert {
    condition     = tolist(output.resource.subnets) == tolist(["/subscriptions/00000000-0000-0000-0000-000000000000/resourceGroups/test-rg/providers/Microsoft.Network/virtualNetworks/test-vnet/subnets/snet1"])
    error_message = "The resource output should list the associated subnets Azure returned."
  }
  providers = {
    azapi  = azapi
    random = random
    time   = time
  }
}

run "bgp_route_propagation_disabled_and_tags" {
  command = apply

  variables {
    bgp_route_propagation_enabled = false
    tags = {
      environment = "test"
    }
  }

  assert {
    condition     = azapi_resource.this.body.properties.disableBgpRoutePropagation && !output.resource.bgp_route_propagation_enabled
    error_message = "Disabling BGP route propagation should be sent as disableBgpRoutePropagation."
  }
  assert {
    condition     = azapi_resource.this.tags["environment"] == "test" && output.resource.tags["environment"] == "test"
    error_message = "Tags should be applied to the route table."
  }
  providers = {
    azapi  = azapi
    random = random
    time   = time
  }
}

run "parent_id_and_resource_types" {
  command = apply

  variables {
    parent_id = "/subscriptions/22222222-2222-2222-2222-222222222222/resourceGroups/other-rg"
    resource_types = {
      network_route_tables = "Microsoft.Network/routeTables@2024-05-01"
    }
  }

  assert {
    condition     = azapi_resource.this.parent_id == var.parent_id && output.resource.resource_group_name == "other-rg"
    error_message = "The route table should be created in parent_id, and the resource output should name its resource group."
  }
  assert {
    condition     = azapi_resource.this.type == "Microsoft.Network/routeTables@2024-05-01"
    error_message = "resource_types should override the route table API version."
  }
  providers = {
    azapi  = azapi
    random = random
    time   = time
  }
}

run "routes_use_the_submodule" {
  command = apply

  variables {
    routes = {
      nva = {
        name                   = "to-nva"
        address_prefix         = "10.1.0.0/16"
        next_hop_type          = "VirtualAppliance"
        next_hop_in_ip_address = "10.0.0.4"
      }
      local = {
        name           = "local"
        address_prefix = "10.2.0.0/16"
        next_hop_type  = "VnetLocal"
      }
    }
  }

  assert {
    condition     = length(module.routes) == 2 && length(azapi_resource.legacy_routes) == 0
    error_message = "Routes should be created by the route submodule unless legacy mode is enabled."
  }
  assert {
    condition     = output.routes["nva"].name == "to-nva" && output.routes["local"].name == "local" && output.routes["nva"].resource_id != ""
    error_message = "The routes output should expose the submodule outputs keyed like the routes input."
  }
  providers = {
    azapi  = azapi
    random = random
    time   = time
  }
}

run "legacy_mode_routes" {
  command = apply

  variables {
    routes_legacy_mode = true
    routes = {
      nva = {
        name                   = "to-nva"
        address_prefix         = "10.1.0.0/16"
        next_hop_type          = "VirtualAppliance"
        next_hop_in_ip_address = "10.0.0.4"
      }
      local = {
        name           = "local"
        address_prefix = "10.2.0.0/16"
        next_hop_type  = "VnetLocal"
      }
    }
  }

  assert {
    condition     = length(module.routes) == 0 && length(azapi_resource.legacy_routes) == 2
    error_message = "Legacy mode should manage the routes in the root module."
  }
  assert {
    condition     = azapi_resource.legacy_routes["nva"].type == "Microsoft.Network/routeTables/routes@2022-09-01" && azapi_resource.legacy_routes["nva"].parent_id == azapi_resource.this.id && azapi_resource.legacy_routes["nva"].name == "to-nva"
    error_message = "Legacy routes should use the submodule's default API version and belong to the route table."
  }
  assert {
    condition     = azapi_resource.legacy_routes["nva"].body.properties.addressPrefix == "10.1.0.0/16" && azapi_resource.legacy_routes["nva"].body.properties.nextHopType == "VirtualAppliance" && azapi_resource.legacy_routes["nva"].body.properties.nextHopIpAddress == "10.0.0.4"
    error_message = "Legacy routes should send the configured route."
  }
  assert {
    condition     = output.routes["to-nva"].next_hop_in_ip_address == "10.0.0.4" && output.routes["local"].next_hop_in_ip_address == "" && output.routes["local"].route_table_name == "test-rt" && output.routes["local"].resource_group_name == "test-rg"
    error_message = "The legacy routes output should be keyed by route name with the AzureRM attribute names and empty values."
  }
  providers = {
    azapi  = azapi
    random = random
    time   = time
  }
}

run "routes_resource_type_applies_to_legacy_routes" {
  command = apply

  variables {
    routes_legacy_mode = true
    resource_types = {
      network_route_tables_routes = {
        network_route_tables_routes = "Microsoft.Network/routeTables/routes@2024-05-01"
      }
    }
    routes = {
      local = {
        name           = "local"
        address_prefix = "10.2.0.0/16"
        next_hop_type  = "VnetLocal"
      }
    }
  }

  assert {
    condition     = azapi_resource.legacy_routes["local"].type == "Microsoft.Network/routeTables/routes@2024-05-01"
    error_message = "The route resource type override should also apply to legacy routes."
  }
  providers = {
    azapi  = azapi
    random = random
    time   = time
  }
}

run "lock_and_role_assignments" {
  command = apply

  variables {
    lock = { kind = "CanNotDelete" }
    role_assignments = {
      reader = {
        principal_id                     = "00000000-0000-0000-0000-000000000001"
        role_definition_id_or_name       = "reader"
        description                      = "Read the test route table"
        skip_service_principal_aad_check = true
      }
    }
  }

  assert {
    condition     = azapi_resource.lock[0].name == "lock-CanNotDelete" && azapi_resource.lock[0].parent_id == azapi_resource.this.id && azapi_resource.lock[0].body.properties.level == "CanNotDelete"
    error_message = "The lock must keep its route table scope, name and level."
  }
  assert {
    condition     = azapi_resource.lock[0].body.properties.notes == "Cannot delete the resource or its child resources." && time_sleep.lock_removal[0].destroy_duration == "30s"
    error_message = "The lock should keep the notes earlier versions wrote, and removing it should pause before the route table is deleted."
  }
  assert {
    condition     = azapi_resource.role_assignments["reader"].parent_id == azapi_resource.this.id && azapi_resource.role_assignments["reader"].body.properties.description == "Read the test route table"
    error_message = "Role assignments must keep their scope and send the documented description."
  }
  assert {
    condition     = azapi_resource.role_assignments["reader"].body.properties.roleDefinitionId == "/subscriptions/00000000-0000-0000-0000-000000000000/providers/Microsoft.Authorization/roleDefinitions/acdd72a7-3385-48ef-bd42-f606fba81ae7" && azapi_resource.role_assignments["reader"].body.properties.principalType == "ServicePrincipal"
    error_message = "Role names should resolve ignoring case, and skip_service_principal_aad_check should send the ServicePrincipal principal type."
  }
  assert {
    condition     = data.azapi_resource_list.role_definitions[0].parent_id == "/subscriptions/00000000-0000-0000-0000-000000000000/resourceGroups/test-rg"
    error_message = "Role definitions should be listed in the resource group."
  }
  providers = {
    azapi  = azapi
    random = random
    time   = time
  }
}

run "lock_name_and_notes" {
  command = apply

  variables {
    lock = {
      kind  = "ReadOnly"
      name  = "custom-lock"
      notes = "Managed by the network team."
    }
  }

  assert {
    condition     = azapi_resource.lock[0].name == "custom-lock" && azapi_resource.lock[0].body.properties.level == "ReadOnly" && azapi_resource.lock[0].body.properties.notes == "Managed by the network team."
    error_message = "The lock should use the configured name and notes."
  }
  providers = {
    azapi  = azapi
    random = random
    time   = time
  }
}

run "retry_and_timeouts" {
  command = apply

  variables {
    lock               = { kind = "CanNotDelete" }
    routes_legacy_mode = true
    retry = {
      error_message_regex  = ["AnotherOperationInProgress"]
      interval_seconds     = 5
      max_interval_seconds = 30
    }
    timeouts = {
      create = "10m"
      delete = "11m"
      read   = "2m"
      update = "12m"
    }
    routes = {
      local = {
        name           = "local"
        address_prefix = "10.2.0.0/16"
        next_hop_type  = "VnetLocal"
      }
    }
  }

  assert {
    condition     = azapi_resource.this.retry.interval_seconds == 5 && azapi_resource.legacy_routes["local"].retry.max_interval_seconds == 30 && azapi_resource.lock[0].retry.error_message_regex[0] == "AnotherOperationInProgress"
    error_message = "retry should be applied to every AzAPI resource."
  }
  assert {
    condition     = azapi_resource.this.timeouts.create == "10m" && azapi_resource.legacy_routes["local"].timeouts.update == "12m" && azapi_resource.lock[0].timeouts.delete == "11m"
    error_message = "timeouts should be applied to every AzAPI resource."
  }
  providers = {
    azapi  = azapi
    random = random
    time   = time
  }
}

run "rejects_subnet_resource_ids" {
  command = plan

  variables {
    subnet_resource_ids = {
      subnet1 = "/subscriptions/00000000-0000-0000-0000-000000000000/resourceGroups/test-rg/providers/Microsoft.Network/virtualNetworks/test-vnet/subnets/snet1"
    }
  }

  expect_failures = [var.subnet_resource_ids]
  providers = {
    azapi  = azapi
    random = random
    time   = time
  }
}

run "rejects_invalid_name" {
  command = plan

  variables {
    name = "-invalid"
  }

  expect_failures = [var.name]
  providers = {
    azapi  = azapi
    random = random
    time   = time
  }
}

run "rejects_invalid_route_name" {
  command = plan

  variables {
    routes = {
      invalid = {
        name           = "invalid route"
        address_prefix = "10.2.0.0/16"
        next_hop_type  = "VnetLocal"
      }
    }
  }

  expect_failures = [var.routes]
  providers = {
    azapi  = azapi
    random = random
    time   = time
  }
}

run "rejects_invalid_parent_id" {
  command = plan

  variables {
    parent_id = "/subscriptions/00000000-0000-0000-0000-000000000000"
  }

  expect_failures = [var.parent_id]
  providers = {
    azapi  = azapi
    random = random
    time   = time
  }
}
