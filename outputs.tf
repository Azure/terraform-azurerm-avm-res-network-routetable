output "name" {
  description = "The route table name"
  value       = azapi_resource.this.name
}

output "resource" {
  description = <<-EOT
  The route table, with the attribute names and empty values of the `azurerm_route_table` resource that earlier versions of this module returned, so that existing references keep working. Prefer `resource_id` and `name`.
  `route` and `subnets` list what Azure returned when the route table was last read, so they do not include routes created in the same apply until the next refresh.
  Examples:
  - module.route_table.resource.id
  - module.route_table.resource.name
  EOT
  value = {
    bgp_route_propagation_enabled = var.bgp_route_propagation_enabled
    id                            = azapi_resource.this.id
    location                      = azapi_resource.this.location
    name                          = azapi_resource.this.name
    resource_group_name           = provider::azapi::parse_resource_id("Microsoft.Resources/resourceGroups", local.parent_id).resource_group_name
    route = [
      for route in try(azapi_resource.this.output.properties.routes, []) : {
        address_prefix         = try(route.properties.addressPrefix, "")
        name                   = route.name
        next_hop_in_ip_address = try(route.properties.nextHopIpAddress, "")
        next_hop_type          = try(route.properties.nextHopType, "")
      }
    ]
    subnets = [for subnet in try(azapi_resource.this.output.properties.subnets, []) : subnet.id]
    tags    = azapi_resource.this.tags == null ? tomap({}) : azapi_resource.this.tags
  }
}

output "resource_id" {
  description = "The ID of the route table"
  value       = azapi_resource.this.id
}

output "routes" {
  description = <<-EOT
  The routes. While `routes_legacy_mode` is false, a map of the route submodule's outputs (`name` and `resource_id`), keyed like `routes`.
  While `routes_legacy_mode` is true, a map keyed by route name, with the attribute names of the `azurerm_route` resource that earlier versions of this module returned.
  EOT
  value = var.routes_legacy_mode ? {
    for key, route in azapi_resource.legacy_routes : route.name => {
      address_prefix         = var.routes[key].address_prefix
      id                     = route.id
      name                   = route.name
      next_hop_in_ip_address = var.routes[key].next_hop_in_ip_address == null ? "" : var.routes[key].next_hop_in_ip_address
      next_hop_type          = var.routes[key].next_hop_type
      resource_group_name    = provider::azapi::parse_resource_id("Microsoft.Resources/resourceGroups", local.parent_id).resource_group_name
      route_table_name       = azapi_resource.this.name
    }
  } : module.routes
}
