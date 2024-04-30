data "azurerm_resource_group" "parent" {
  name = var.resource_group_name
}

# Create Route Table
resource "azurerm_route_table" "this" {
  location                      = data.azurerm_resource_group.parent.location
  name                          = var.name
  resource_group_name           = data.azurerm_resource_group.parent.name
  disable_bgp_route_propagation = var.disable_bgp_route_propagation
  tags                          = var.tags
}


# Create routes associated to the Route Table
resource "azurerm_route" "this" {
  for_each = { for idx, route in var.routes : idx => route }

  address_prefix         = each.value.address_prefix
  name                   = each.value.name
  next_hop_type          = each.value.next_hop_type
  resource_group_name    = data.azurerm_resource_group.parent.name
  route_table_name       = azurerm_route_table.this.name
  next_hop_in_ip_address = each.value.next_hop_in_ip_address
}

# Associate route table with VNets
resource "azurerm_subnet_route_table_association" "this" {
  for_each = toset(var.subnets)

  route_table_id = azurerm_route_table.this.id
  subnet_id      = each.value
}

# Applying Management Lock to the Route Table if specified.
resource "azurerm_management_lock" "this" {
  count = var.lock != null ? 1 : 0

  lock_level = var.lock.kind
  name       = coalesce(var.lock.name, "lock-${var.lock.kind}")
  scope      = azurerm_route_table.this.id
  notes      = var.lock.kind == "CanNotDelete" ? "Cannot delete the resource or its child resources." : "Cannot delete or modify the resource or its child resources."
}

# Apply resource level IaM.
resource "azurerm_role_assignment" "this" {
  for_each = var.role_assignments

  principal_id                           = each.value.principal_id
  scope                                  = azurerm_route_table.this.id
  condition                              = each.value.condition
  condition_version                      = each.value.condition_version
  delegated_managed_identity_resource_id = each.value.delegated_managed_identity_resource_id
  role_definition_id                     = strcontains(lower(each.value.role_definition_id_or_name), lower(local.role_definition_resource_substring)) ? each.value.role_definition_id_or_name : null
  role_definition_name                   = strcontains(lower(each.value.role_definition_id_or_name), lower(local.role_definition_resource_substring)) ? null : each.value.role_definition_id_or_name
  skip_service_principal_aad_check       = each.value.skip_service_principal_aad_check
}
