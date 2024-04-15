##########################################
### TODO: Add route table subnet assoc ###
##########################################

data "azurerm_resource_group" "parent" {
  count = var.location == null ? 1 : 0

  name = var.resource_group_name
}

# Create Route Table
resource "azurerm_route_table" "this" {
  location                      = var.location
  name                          = var.route_table_name
  resource_group_name           = var.resource_group_name
  disable_bgp_route_propagation = var.disable_bgp_route_propagation
  tags                          = var.tags
}

# Create routes associated to the Route Table
resource "azurerm_route" "this" {
  for_each = { for idx, route in var.routes : idx => route }

  address_prefix         = each.value.address_prefix
  name                   = each.value.name
  next_hop_type          = each.value.next_hop_type
  resource_group_name    = azurerm_route_table.route_table.resource_group_name
  route_table_name       = azurerm_route_table.route_table.name
  next_hop_in_ip_address = each.value.next_hop_in_ip_address
}

# Associate route table with VNets
resource "azurerm_subnet_route_table_association" "this" {
  for_each = toset(var.subnets)

  route_table_id = azurerm_route_table.route_table.id
  subnet_id      = each.value
}

# Applying Management Lock to the Route Table if specified.
resource "azurerm_management_lock" "this" {
  count = var.lock.kind != "None" ? 1 : 0

  lock_level = var.lock.kind
  name       = coalesce(var.lock.name, "lock-${var.route_table_name}")
  scope      = azurerm_route_table.route_table.id
}

# Apply resource level IaM.
resource "azurerm_role_assignment" "this" {
  for_each = var.role_assignments

  principal_id                           = each.value.principal_id
  scope                                  = azurerm_route_table.this.id # TODO: Replace this dummy resource azurerm_resource_group.TODO with your module resource
  condition                              = each.value.condition
  condition_version                      = each.value.condition_version
  delegated_managed_identity_resource_id = each.value.delegated_managed_identity_resource_id
  role_definition_id                     = strcontains(lower(each.value.role_definition_id_or_name), lower(local.role_definition_resource_substring)) ? each.value.role_definition_id_or_name : null
  role_definition_name                   = strcontains(lower(each.value.role_definition_id_or_name), lower(local.role_definition_resource_substring)) ? null : each.value.role_definition_id_or_name
  skip_service_principal_aad_check       = each.value.skip_service_principal_aad_check
}
