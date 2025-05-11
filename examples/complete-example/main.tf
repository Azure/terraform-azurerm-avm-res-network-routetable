terraform {
  required_version = ">= 1.9, < 2.0"
  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = "~> 4.0"
    }
    random = {
      source  = "hashicorp/random"
      version = ">= 3.5.0, < 4.0.0"
    }
  }
}

provider "azurerm" {
  features {}
}


## Section to provide a random Azure region for the resource group
# This allows us to randomize the region for the resource group.
module "regions" {
  source  = "Azure/regions/azurerm"
  version = ">= 0.3.0"
}

# This allows us to randomize the region for the resource group.
resource "random_integer" "region_index" {
  max = length(module.regions.regions) - 1
  min = 0
}
## End of section to provide a random Azure region for the resource group

# This ensures we have unique CAF compliant names for our resources.
module "naming" {
  source  = "Azure/naming/azurerm"
  version = ">= 0.3.0"
}

# This is required for resource modules
resource "azurerm_resource_group" "this" {
  location = module.regions.regions[random_integer.region_index.result].name
  name     = module.naming.resource_group.name_unique
}

resource "azurerm_virtual_network" "this" {
  address_space       = ["10.0.0.0/16"]
  location            = azurerm_resource_group.this.location
  name                = module.naming.virtual_network.name_unique
  resource_group_name = azurerm_resource_group.this.name
}

resource "azurerm_subnet" "this" {
  count = 2

  address_prefixes     = ["10.0.${count.index}.0/24"]
  name                 = format("%s%d", module.naming.subnet.name_unique, count.index)
  resource_group_name  = azurerm_resource_group.this.name
  virtual_network_name = azurerm_virtual_network.this.name
}

module "test_route_table" {
  source = "../../"

  location            = azurerm_resource_group.this.location
  name                = module.naming.route_table.name_unique
  resource_group_name = azurerm_resource_group.this.name
  enable_telemetry    = var.enable_telemetry
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
  subnet_resource_ids = {
    subnet1 = azurerm_subnet.this[0].id,
    subnet2 = azurerm_subnet.this[1].id
  }
}



