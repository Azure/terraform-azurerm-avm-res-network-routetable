data "azapi_client_config" "current" {}

resource "azapi_resource" "this" {
  location  = var.location
  name      = var.name
  parent_id = local.parent_id
  type      = var.resource_types.network_route_tables
  body = {
    properties = {
      disableBgpRoutePropagation = !var.bgp_route_propagation_enabled
      routes                     = []
    }
  }
  # Routes are managed as separate resources. The empty list above is always ignored, so on update the
  # provider re-reads the route table and sends the live routes instead, as the AzureRM provider did. A PUT
  # that omits the routes deletes all of them.
  ignore_body_changes = distinct(concat(["properties.routes"], var.ignore_body_changes.network_route_tables))
  response_export_values = [
    "properties.routes",
    "properties.subnets",
  ]
  retry = var.retry
  tags  = var.tags

  dynamic "timeouts" {
    for_each = var.timeouts == null ? [] : [var.timeouts]

    content {
      create = timeouts.value.create
      delete = timeouts.value.delete
      read   = timeouts.value.read
      update = timeouts.value.update
    }
  }

  lifecycle {
    # Keeps the planned body consistent with the routes in state, which AzAPI cannot fit into the empty
    # list. The routes actually sent come from the live read described above.
    ignore_changes = [body.properties.routes]
  }
}

module "routes" {
  source   = "./modules/route"
  for_each = var.routes_legacy_mode ? {} : var.routes

  address_prefix      = each.value.address_prefix
  name                = each.value.name
  next_hop_type       = each.value.next_hop_type
  parent_id           = azapi_resource.this.id
  enable_telemetry    = var.enable_telemetry
  ignore_body_changes = var.ignore_body_changes.network_route_tables_routes
  location            = var.location
  next_hop_ip_address = each.value.next_hop_in_ip_address
  resource_types      = var.resource_types.network_route_tables_routes
  retry               = var.retry
  timeouts            = var.timeouts
}

# While `routes_legacy_mode` is true, the routes keep the addresses that version 0.4.x and earlier gave
# them, and are otherwise managed like the routes of the submodule.
resource "azapi_resource" "legacy_routes" {
  for_each = var.routes_legacy_mode ? var.routes : {}

  name      = each.value.name
  parent_id = azapi_resource.this.id
  type      = local.route_resource_type
  body = {
    properties = {
      addressPrefix    = each.value.address_prefix
      nextHopIpAddress = each.value.next_hop_in_ip_address
      nextHopType      = each.value.next_hop_type
    }
  }
  ignore_body_changes    = length(var.ignore_body_changes.network_route_tables_routes.network_route_tables_routes) > 0 ? var.ignore_body_changes.network_route_tables_routes.network_route_tables_routes : null
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

resource "azapi_resource" "lock" {
  count = var.lock != null ? 1 : 0

  name      = coalesce(var.lock.name, "lock-${var.lock.kind}")
  parent_id = azapi_resource.this.id
  type      = var.resource_types.authorization_locks
  body = {
    properties = {
      level = var.lock.kind
      notes = coalesce(var.lock.notes, local.lock_notes[var.lock.kind])
    }
  }
  ignore_body_changes    = length(var.ignore_body_changes.authorization_locks) > 0 ? var.ignore_body_changes.authorization_locks : null
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

  # Create the lock last and remove it first. A ReadOnly lock blocks changes to the routes and role
  # assignments, and a CanNotDelete lock blocks deleting the routes.
  depends_on = [time_sleep.lock_removal]
}

# Azure keeps enforcing a deleted lock for a few seconds, and the AzAPI provider does not wait for it to be
# gone as the AzureRM provider did. This pause is destroyed after the lock and before the route table and the
# resources under it, so they are not deleted while the lock still applies.
resource "time_sleep" "lock_removal" {
  count = var.lock != null ? 1 : 0

  destroy_duration = "30s"
  # Replacing the route table replaces its lock, so the pause is replaced with them.
  triggers = {
    route_table_id = azapi_resource.this.id
  }

  depends_on = [
    azapi_resource.legacy_routes,
    azapi_resource.role_assignments,
    module.routes,
  ]
}

# Role definitions are resolved here, case-insensitively as the AzureRM provider did, rather than by the
# interfaces module, whose lookup is case-sensitive. They are listed in the resource group rather than on
# the route table, so the lookup does not wait for pending changes to the route table and a role name that
# does not exist fails during plan.
data "azapi_resource_list" "role_definitions" {
  count = length(var.role_assignments) > 0 ? 1 : 0

  parent_id = local.parent_id
  type      = "Microsoft.Authorization/roleDefinitions@2022-04-01"
  response_export_values = {
    results = "value[].{id: id, role_name: properties.roleName}"
  }
}

module "avm_interfaces" {
  source  = "Azure/avm-utl-interfaces/azure"
  version = "0.9.0"

  location                                  = var.location
  enable_telemetry                          = var.enable_telemetry
  role_assignment_definition_lookup_enabled = false
  role_assignments                          = local.role_assignments
}

resource "azapi_resource" "role_assignments" {
  for_each = var.role_assignments

  name                 = module.avm_interfaces.role_assignments_azapi[each.key].name
  parent_id            = azapi_resource.this.id
  type                 = var.resource_types.authorization_role_assignments
  body                 = module.avm_interfaces.role_assignments_azapi[each.key].body
  ignore_body_changes  = length(var.ignore_body_changes.authorization_role_assignments) > 0 ? var.ignore_body_changes.authorization_role_assignments : null
  ignore_casing        = true
  ignore_null_property = true
  # The AzureRM provider replaced a role assignment whenever one of its inputs changed. The inputs are
  # compared, rather than body paths or the resolved role definition ID, because Azure normalises role
  # definition IDs. While the prior value is null, as it is straight after upgrading from AzureRM,
  # nothing is replaced.
  replace_triggers_external_values = {
    condition                              = each.value.condition
    condition_version                      = each.value.condition_version
    delegated_managed_identity_resource_id = each.value.delegated_managed_identity_resource_id
    description                            = each.value.description
    name                                   = each.value.name
    principal_id                           = lower(each.value.principal_id)
    principal_type                         = local.role_assignments[each.key].principal_type
    role_definition_id_or_name             = lower(each.value.role_definition_id_or_name)
  }
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

  lifecycle {
    # Upgraded assignments keep the GUID the AzureRM provider generated, while the interfaces module
    # generates a new one. Replacing them would fail under a CanNotDelete lock. A change to an explicit
    # name still replaces the assignment through replace_triggers_external_values.
    ignore_changes = [name]

    precondition {
      condition     = strcontains(lower(local.role_assignments[each.key].role_definition_id_or_name), local.role_definition_resource_substring)
      error_message = "The role definition `${each.value.role_definition_id_or_name}` was not found in the resource group. Use the name of a role definition that can be assigned there, or the role definition's resource ID."
    }
  }
}
