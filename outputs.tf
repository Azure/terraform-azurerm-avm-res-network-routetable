output "route_table" {
  description = "This is the full output for the route table."
  value       = resource.azurerm_route_table.this
}

output "route_table_resource_id" {
  description = "The ID of the route table"
  value       = resource.azurerm_route_table.this.id
}

output "routes" {
  description = "This is the full output for the routes."
  value = zipmap(
    [for route in var.routes : route.name],
    values(azurerm_route.this)[*]
  )
}
