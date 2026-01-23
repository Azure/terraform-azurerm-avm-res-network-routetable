output "name" {
  description = "The name of the route."
  value       = azurerm_route.this.name
}

output "resource_id" {
  description = "The resource ID of the route."
  value       = azurerm_route.this.id
}
