# The route table, legacy-mode routes, lock and role assignments moved from the AzureRM provider to AzAPI.
# They are adopted in place and updated with the same settings.
moved {
  from = azurerm_route_table.this
  to   = azapi_resource.this
}

moved {
  from = azurerm_route.this
  to   = azapi_resource.legacy_routes
}

moved {
  from = azurerm_management_lock.this
  to   = azapi_resource.lock
}

moved {
  from = azurerm_role_assignment.this
  to   = azapi_resource.role_assignments
}

# Subnet associations are no longer managed by this module. They are removed from the state and kept in
# Azure, so upgrading does not change how any subnet is routed.
removed {
  from = azurerm_subnet_route_table_association.this

  lifecycle {
    destroy = false
  }
}
