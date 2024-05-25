locals {
  resource_group_location            = try(data.azurerm_resource_group.parent.location, null)
  role_definition_resource_substring = "/providers/Microsoft.Authorization/roleDefinitions"
}