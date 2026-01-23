resource "azapi_resource" "route" {
  name      = var.name
  parent_id = var.parent_id
  type      = "Microsoft.Network/routeTables/routes@2022-09-01"
  body = {
    properties = {
      addressPrefix    = var.address_prefix
      nextHopType      = var.next_hop_type
      nextHopIpAddress = var.next_hop_ip_address
    }
  }
  response_export_values = []
}
