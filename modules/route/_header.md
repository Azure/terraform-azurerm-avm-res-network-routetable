# Azure Route Table Root Module

This module is used to manage Azure Route Table Routes.

## Usage

To use this module in your Terraform configuration, you'll need to provide values for the required variables.

### Example

This example shows the basic usage of the module.

```terraform
module "avm-res-network-routetable-route" {
  source = "Azure/avm-res-network-routetable/azurerm//modules/route"

  resource_group_name    = "example-resource-group"
  route_table_name       = "example-route-table"
  route_name             = "example-route"
  address_prefix         = "10.0.0.0/24"
  next_hop_type          = "VirtualAppliance"
  next_hop_in_ip_address = "10.0.0.5"
}
```
