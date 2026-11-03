mock_provider "azapi" {
  mock_resource "azapi_resource" {
    defaults = {
      id = "/subscriptions/00000000-0000-0000-0000-000000000000/resourceGroups/test-rg/providers/Microsoft.Network/routeTables/test-rt/routes/to-nva"
    }
  }
  mock_data "azapi_client_config" {
    defaults = {
      subscription_resource_id = "/subscriptions/00000000-0000-0000-0000-000000000000"
    }
  }
}

variables {
  address_prefix      = "10.1.0.0/16"
  enable_telemetry    = false
  name                = "to-nva"
  next_hop_ip_address = "10.0.0.4"
  next_hop_type       = "VirtualAppliance"
  parent_id           = "/subscriptions/00000000-0000-0000-0000-000000000000/resourceGroups/test-rg/providers/Microsoft.Network/routeTables/test-rt"
}

run "defaults" {
  command = apply

  assert {
    condition     = azapi_resource.this.type == "Microsoft.Network/routeTables/routes@2022-09-01" && azapi_resource.this.parent_id == var.parent_id && azapi_resource.this.name == "to-nva"
    error_message = "The route should use the default API version and belong to the route table."
  }
  assert {
    condition     = azapi_resource.this.body.properties.addressPrefix == "10.1.0.0/16" && azapi_resource.this.body.properties.nextHopType == "VirtualAppliance" && azapi_resource.this.body.properties.nextHopIpAddress == "10.0.0.4"
    error_message = "The route should send the configured address prefix and next hop."
  }
  assert {
    condition     = output.name == "to-nva" && output.resource_id == azapi_resource.this.id
    error_message = "The outputs should describe the route."
  }
}

run "resource_types_retry_and_timeouts" {
  command = apply

  variables {
    resource_types = {
      network_route_tables_routes = "Microsoft.Network/routeTables/routes@2024-05-01"
    }
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
  }

  assert {
    condition     = azapi_resource.this.type == "Microsoft.Network/routeTables/routes@2024-05-01"
    error_message = "resource_types should override the route API version."
  }
  assert {
    condition     = azapi_resource.this.retry.interval_seconds == 5 && azapi_resource.this.timeouts.create == "10m" && azapi_resource.this.timeouts.delete == "11m"
    error_message = "retry and timeouts should be applied to the route."
  }
}

run "rejects_invalid_parent_id" {
  command = plan

  variables {
    parent_id = "/subscriptions/00000000-0000-0000-0000-000000000000/resourceGroups/test-rg"
  }

  expect_failures = [var.parent_id]
}

run "rejects_invalid_next_hop_type" {
  command = plan

  variables {
    next_hop_type = "Firewall"
  }

  expect_failures = [var.next_hop_type]
}
