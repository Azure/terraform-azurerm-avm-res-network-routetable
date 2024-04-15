# TODO: insert locals here.
locals {
  resource_group_location            = try(data.azurerm_resource_group.parent[0].location, null)
  role_definition_resource_substring = "/providers/Microsoft.Authorization/roleDefinitions"
}