terraform {
  required_version = ">= 1.11, < 2.0"

  required_providers {
    azapi = {
      source  = "Azure/azapi"
      version = "~> 2.12"
    }
    random = {
      source  = "hashicorp/random"
      version = "~> 3.5"
    }
  }
}

# This picks a random region from the list of regions.
resource "random_integer" "region_index" {
  max = length(local.azure_regions) - 1
  min = 0
}

# This ensures we have unique CAF compliant names for our resources.
module "naming" {
  source  = "Azure/avm-utl-naming/azure"
  version = "0.3.0"
}

# This is required for resource modules
resource "azapi_resource" "resource_group" {
  location = local.azure_regions[random_integer.region_index.result]
  name     = module.naming.resource_group.name_unique
  type     = "Microsoft.Resources/resourceGroups@2024-03-01"
}

module "test_route_table" {
  source = "../../"

  location         = azapi_resource.resource_group.location
  name             = module.naming.route_table.name_unique
  parent_id        = azapi_resource.resource_group.id
  enable_telemetry = var.enable_telemetry
  lock = {
    kind = "CanNotDelete"
    name = "Example-Lock"
  }
  routes = {
    test-route-vnetlocal = {
      name           = "test-route-vnetlocal"
      address_prefix = "10.2.0.0/32"
      next_hop_type  = "VnetLocal"
    },
    test-route-nva = {
      name                   = "test-route-nva"
      address_prefix         = "10.1.0.0/24"
      next_hop_type          = "VirtualAppliance"
      next_hop_in_ip_address = "10.0.0.1"
    },
    test-route-vnetlocal2 = {
      name           = "test-route-vnetlocal2"
      address_prefix = "10.1.0.0/16"
      next_hop_type  = "VnetLocal"
    },
    test-route-vnetgateway = {
      name           = "test-route-vnetgateway"
      address_prefix = "10.0.0.0/8"
      next_hop_type  = "VirtualNetworkGateway"
    },
    test-route-internet = {
      name           = "test-route-internet"
      address_prefix = "0.0.0.0/0"
      next_hop_type  = "Internet"
    }
  }
}

# Each subnet is associated with the route table in its own configuration.
resource "azapi_resource" "virtual_network" {
  location  = azapi_resource.resource_group.location
  name      = module.naming.virtual_network.name_unique
  parent_id = azapi_resource.resource_group.id
  type      = "Microsoft.Network/virtualNetworks@2024-05-01"
  body = {
    properties = {
      addressSpace = {
        addressPrefixes = ["10.0.0.0/16"]
      }
      subnets = [
        for index in range(2) : {
          name = format("%s%d", module.naming.subnet.name_unique, index)
          properties = {
            addressPrefix = "10.0.${index}.0/24"
            routeTable = {
              id = module.test_route_table.resource_id
            }
          }
        }
      ]
    }
  }
}
