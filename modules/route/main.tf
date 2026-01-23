resource "azurerm_route" "this" {
  address_prefix         = var.address_prefix
  name                   = var.name
  next_hop_type          = var.next_hop_type
  resource_group_name    = var.resource_group_name
  route_table_name       = var.route_table_name
  next_hop_in_ip_address = var.next_hop_in_ip_address
}
