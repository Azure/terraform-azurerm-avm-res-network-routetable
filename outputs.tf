output "route_table" {
  description = "This is the full output for the route table."
  value       = resource.azurerm_route_table.route_table
}

output "routes" {
  description = "This is the full output for the routes."
  value = zipmap(
    [for route in var.routes : route.name],
    values(azurerm_route.route)[*]
  )
}

output "route_table_resource_id" {
  value       = resource.azurerm_route_table.route_table.id
  description = "The ID of the route table"
}
