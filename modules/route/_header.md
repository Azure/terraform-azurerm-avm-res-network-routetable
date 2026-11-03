# Route submodule

This submodule manages one route in an existing route table. The root module calls it for each entry in `routes`, and it can also be called directly.

## Usage

```terraform
module "route" {
  source = "Azure/avm-res-network-routetable/azurerm//modules/route"

  address_prefix      = "10.0.0.0/24"
  location            = "westeurope"
  name                = "example-route"
  next_hop_ip_address = "10.0.0.5"
  next_hop_type       = "VirtualAppliance"
  parent_id           = "/subscriptions/00000000-0000-0000-0000-000000000000/resourceGroups/example-rg/providers/Microsoft.Network/routeTables/example-route-table"
}
```

`location` is only used for the telemetry deployment and can be omitted when `enable_telemetry` is `false`.