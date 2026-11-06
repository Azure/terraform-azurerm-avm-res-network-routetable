resource "azapi_resource" "this" {
  name      = var.name
  parent_id = var.parent_id
  type      = var.resource_types.network_route_tables_routes
  body = {
    properties = {
      addressPrefix    = var.address_prefix
      nextHopIpAddress = var.next_hop_ip_address
      nextHopType      = var.next_hop_type
    }
  }
  ignore_body_changes    = length(var.ignore_body_changes.network_route_tables_routes) > 0 ? var.ignore_body_changes.network_route_tables_routes : null
  response_export_values = []
  retry                  = var.retry

  dynamic "timeouts" {
    for_each = var.timeouts == null ? [] : [var.timeouts]

    content {
      create = timeouts.value.create
      delete = timeouts.value.delete
      read   = timeouts.value.read
      update = timeouts.value.update
    }
  }
}

moved {
  from = azapi_resource.route
  to   = azapi_resource.this
}
