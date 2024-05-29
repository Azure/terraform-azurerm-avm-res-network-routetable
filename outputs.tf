output "name" {
  description = "The route table name"
  value       = resource.azurerm_route_table.this.name
}

output "resource" {
  description = "This is the full output for the route table."
  value       = resource.azurerm_route_table.this
}

output "resource_id" {
  description = "The ID of the route table"
  value       = resource.azurerm_route_table.this.id
}

output "routes" {
  description = "This is the full output of the routes."
  value = zipmap(
    [for route in var.routes : route.name],
    values(azurerm_route.this)[*]
  )
}
