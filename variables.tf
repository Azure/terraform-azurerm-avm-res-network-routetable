variable "location" {
  type        = string
  description = <<DESCRIPTION
    (Required) Specifies the supported Azure location for the resource to be deployed.
    Changing this forces a new resource to be created.
  DESCRIPTION
  nullable    = false
}

variable "name" {
  type        = string
  description = "(Required) Specifies the name of the Route Table. Changing this forces a new resource to be created."
  nullable    = false

  validation {
    condition     = can(regex("^[a-zA-Z0-9][a-zA-Z0-9_.-]{0,78}[a-zA-Z0-9_]?$", var.name))
    error_message = "The name must be 1 to 80 characters long, start with a letter or a number, and contain only letters, numbers, underscores, periods and hyphens."
  }
}

variable "resource_group_name" {
  type        = string
  description = "(Required) The name of the resource group in which to create the resource. Ignored when `parent_id` is set. Changing this forces a new resource to be created."
  nullable    = false
}

variable "bgp_route_propagation_enabled" {
  type        = bool
  default     = true
  description = "(Optional) Boolean flag which controls propagation of routes learned by BGP on that route table. Defaults to true."
  nullable    = false
}

variable "enable_telemetry" {
  type        = bool
  default     = true
  description = <<DESCRIPTION
This variable controls whether or not telemetry is enabled for the module.
For more information see <https://aka.ms/avm/telemetryinfo>.
If it is set to false, then no telemetry will be collected.
DESCRIPTION
  nullable    = false
}

variable "ignore_body_changes" {
  type = object({
    authorization_locks            = optional(list(string), [])
    authorization_role_assignments = optional(list(string), [])
    network_route_tables           = optional(list(string), [])
    network_route_tables_routes = optional(object({
      network_route_tables_routes = optional(list(string), [])
    }), {})
  })
  default     = {}
  description = <<DESCRIPTION
Paths in each resource's `body` whose changes the AzAPI provider ignores. Prefer Terraform's `lifecycle.ignore_changes` when the paths are static; use this variable when the paths must be derived from variables or other non-static values.

Paths use dot notation, for example `properties.sku.name`. Individual list items cannot be targeted — ignore the whole list property instead. Configuration changes at an ignored path are **not** sent to Azure until that path is removed from the list.

Supplying a non-empty value requires Terraform 1.11 or later, because `ignore_body_changes` is a write-only argument. Changes take effect only after an apply, because the value is held in provider-private state.

- `authorization_locks` - Ignored body paths for the management lock.
- `authorization_role_assignments` - Ignored body paths for the role assignments.
- `network_route_tables` - Ignored body paths for the route table. `properties.routes` is always ignored in addition to these paths, because the routes are managed as separate resources and updating the route table must not remove them.
- `network_route_tables_routes` - Override slot for the route submodule. Supply only the keys you want to override.
  - `network_route_tables_routes` - Ignored body paths for the routes. Also applies to the routes managed while `routes_legacy_mode` is true.
DESCRIPTION
  nullable    = false
}

variable "lock" {
  type = object({
    kind  = string
    name  = optional(string, null)
    notes = optional(string, null)
  })
  default     = null
  description = <<DESCRIPTION
Controls the Resource Lock configuration for this resource. The following properties can be specified:

- `kind` - (Required) The type of lock. Possible values are `\"CanNotDelete\"` and `\"ReadOnly\"`.
- `name` - (Optional) The name of the lock. If not specified, a name will be generated based on the `kind` value. Changing this forces the creation of a new resource.
- `notes` - (Optional) Notes about the lock. This value maps to `Microsoft.Authorization/locks.properties.notes`. If not specified, a note describing the lock `kind` is used.

A `ReadOnly` lock also blocks changes to the routes and role assignments, and a `CanNotDelete` lock blocks deleting routes.
DESCRIPTION

  validation {
    condition     = var.lock != null ? contains(["CanNotDelete", "ReadOnly"], var.lock.kind) : true
    error_message = "Lock kind must be either `\"CanNotDelete\"` or `\"ReadOnly\"`."
  }
}

variable "parent_id" {
  type        = string
  default     = null
  description = "The resource ID of the resource group in which to create the route table, for example `/subscriptions/00000000-0000-0000-0000-000000000000/resourceGroups/example-rg`. When provided, takes precedence over `resource_group_name`. Changing this forces a new resource to be created."

  validation {
    condition     = var.parent_id == null || can(provider::azapi::parse_resource_id("Microsoft.Resources/resourceGroups", var.parent_id))
    error_message = "`parent_id` must be a valid Azure resource group resource ID, or null."
  }
}

variable "resource_types" {
  type = object({
    authorization_locks            = optional(string, "Microsoft.Authorization/locks@2020-05-01")
    authorization_role_assignments = optional(string, "Microsoft.Authorization/roleAssignments@2022-04-01")
    network_route_tables           = optional(string, "Microsoft.Network/routeTables@2025-01-01")
    network_route_tables_routes = optional(object({
      network_route_tables_routes = optional(string)
    }), {})
  })
  default     = {}
  description = <<DESCRIPTION
AzAPI resource types and API versions used by the module, in `<provider>/<resource>@<api-version>` form. Each key defaults to a tested value; supply only the keys you want to override, for example to target a sovereign cloud that serves older API versions.

- `authorization_locks` - The management lock.
- `authorization_role_assignments` - The role assignments.
- `network_route_tables` - The route table.
- `network_route_tables_routes` - Override slot for the route submodule. Defaults live in the submodule; supply only the keys you want to override.
  - `network_route_tables_routes` - The routes. Also applies to the routes managed while `routes_legacy_mode` is true.
DESCRIPTION
  nullable    = false
}

variable "retry" {
  type = object({
    error_message_regex  = optional(list(string))
    interval_seconds     = optional(number)
    max_interval_seconds = optional(number)
  })
  default     = null
  description = <<DESCRIPTION
Retry configuration applied to every `azapi` resource managed by the module (root resource and all submodules). Defaults to `null` (no custom retry).

- `error_message_regex`  - (Optional) A list of regex patterns matching error messages that trigger a retry.
- `interval_seconds`     - (Optional) Initial interval between retries in seconds.
- `max_interval_seconds` - (Optional) Maximum interval between retries in seconds.

See <https://registry.terraform.io/providers/Azure/azapi/latest/docs/resources/resource#retry> for full semantics.
DESCRIPTION
}

variable "role_assignments" {
  type = map(object({
    name                                   = optional(string, null)
    role_definition_id_or_name             = string
    principal_id                           = string
    description                            = optional(string, null)
    skip_service_principal_aad_check       = optional(bool, false)
    condition                              = optional(string, null)
    condition_version                      = optional(string, null)
    delegated_managed_identity_resource_id = optional(string, null)
    principal_type                         = optional(string, null)
  }))
  default     = {}
  description = <<DESCRIPTION
A map of role assignments to create on the route table. The map key is deliberately arbitrary to avoid issues where map keys maybe unknown at plan time.

- `name` - (Optional) The name of the role assignment. If not set, a random UUID will be generated. Changing this forces the creation of a new resource. Role assignments created by earlier versions of this module keep their existing name.
- `role_definition_id_or_name` - The ID or name of the role definition to assign to the principal. A name is matched, ignoring case, against the role definitions that can be assigned in the resource group. For a custom role that can only be assigned on this route table, use its ID.
- `principal_id` - The ID of the principal to assign the role to.
- `description` - (Optional) The description of the role assignment.
- `skip_service_principal_aad_check` - (Optional) If set to true and `principal_type` is not set, `principal_type` is set to `ServicePrincipal`, which skips the Azure Active Directory check for the service principal in the tenant. Defaults to false.
- `condition` - (Optional) The condition which will be used to scope the role assignment.
- `condition_version` - (Optional) The version of the condition syntax. Leave as `null` if you are not using a condition, if you are then valid values are '2.0'.
- `delegated_managed_identity_resource_id` - (Optional) The delegated Azure Resource Id which contains a Managed Identity. Changing this forces a new resource to be created. This field is only used in cross-tenant scenario.
- `principal_type` - (Optional) The type of the `principal_id`. Possible values are `User`, `Group` and `ServicePrincipal`. It is necessary to explicitly set this attribute when creating role assignments if the principal creating the assignment is constrained by ABAC rules that filters on the PrincipalType attribute.

> Note: only set `skip_service_principal_aad_check` to true if you are assigning a role to a service principal.
DESCRIPTION
  nullable    = false

  validation {
    condition = alltrue([
      for _, v in var.role_assignments :
      v.delegated_managed_identity_resource_id == null || can(provider::azapi::parse_resource_id("Microsoft.ManagedIdentity/userAssignedIdentities", v.delegated_managed_identity_resource_id))
    ])
    error_message = "Each `role_assignments[*].delegated_managed_identity_resource_id` must be a valid user-assigned managed identity resource ID, or null."
  }
}

variable "routes" {
  type = map(object({
    name                   = string
    address_prefix         = string
    next_hop_type          = string
    next_hop_in_ip_address = optional(string)
  }))
  default     = {}
  description = <<DESCRIPTION
    (Optional) A map of route objects to create on the route table.

    - `name` - (Required) The name of the route.
    - `address_prefix` - (Required) The destination to which the route applies. Can be CIDR (such as 10.1.0.0/16) or Azure Service Tag (such as ApiManagement, AzureBackup or AzureMonitor) format.
    - `next_hop_type` - (Required) The type of Azure hop the packet should be sent to. Possible values are VirtualNetworkGateway, VnetLocal, Internet, VirtualAppliance and None.
    - `next_hop_in_ip_address` - (Optional) Contains the IP address packets should be forwarded to. Next hop values are only allowed in routes where the next hop type is VirtualAppliance

    Example Input:

```terraform
routes = {
    route1 = {
      name           = "test-route-vnetlocal"
      address_prefix = "10.2.0.0/32"
      next_hop_type  = "VnetLocal"
    }
}
```
DESCRIPTION
  nullable    = false

  validation {
    condition     = length([for route in var.routes : route.name]) == length(distinct([for route in var.routes : route.name]))
    error_message = "Each route name must be unique within the route table."
  }
  validation {
    condition     = alltrue([for route in var.routes : can(regex("^[a-zA-Z0-9][a-zA-Z0-9_.-]{0,78}[a-zA-Z0-9_]?$", route.name))])
    error_message = "Each route name must be 1 to 80 characters long, start with a letter or a number, and contain only letters, numbers, underscores, periods and hyphens."
  }
  validation {
    condition     = alltrue([for route in var.routes : contains(["VirtualNetworkGateway", "VnetLocal", "Internet", "VirtualAppliance", "None"], route.next_hop_type)])
    error_message = "next_hop_type must be one of 'VirtualNetworkGateway', 'VnetLocal', 'Internet', 'VirtualAppliance' or 'None' for all routes."
  }
  validation {
    condition     = alltrue([for route in var.routes : route.next_hop_type != "VirtualAppliance" ? route.next_hop_in_ip_address == null : true])
    error_message = "If next_hop_type is not VirtualAppliance, next_hop_in_ip_address must be null."
  }
}

variable "routes_legacy_mode" {
  type        = bool
  default     = false
  description = "(Optional) When set to true, the routes are managed at the state addresses that version 0.4.x and earlier of this module used, rather than by the route submodule. Set it to true only for route tables deployed with version 0.4.x or earlier. Defaults to false."
  nullable    = false
}

# Retired, and kept only so that configurations that still set it fail with an explanation rather than an
# unsupported-argument error.
# tflint-ignore: terraform_unused_declarations
variable "subnet_resource_ids" {
  type        = map(string)
  default     = {}
  description = <<DESCRIPTION
(Retired) Must be empty. This module no longer associates the route table with subnets. Associate it in each subnet's configuration instead, for example with the `route_table` attribute of the subnets of the `Azure/avm-res-network-virtualnetwork/azurerm` module, or with the `properties.routeTable.id` property of a subnet. Associations created by earlier versions of this module are kept in Azure when you upgrade. See "Upgrading from 0.6.x or earlier" in the README.
DESCRIPTION
  nullable    = false

  validation {
    condition     = length(var.subnet_resource_ids) == 0
    error_message = "`subnet_resource_ids` is no longer supported. Remove it, and associate the route table in each subnet's configuration instead, for example with the `route_table` attribute of the subnets of the virtual network module. Associations created by earlier versions of this module are kept in Azure. See \"Upgrading from 0.6.x or earlier\" in the README."
  }
}

variable "tags" {
  type        = map(string)
  default     = null
  description = "(Optional) Tags of the resource."
}

variable "timeouts" {
  type = object({
    create = optional(string)
    read   = optional(string)
    update = optional(string)
    delete = optional(string)
  })
  default     = null
  description = <<DESCRIPTION
Default per-operation timeouts applied to every `azapi` resource managed by the module, including those in the route submodule. Defaults to `null` (provider defaults). Each value is a Go duration string (e.g. `30m`, `1h`).

- `create` - (Optional) Timeout for create operations.
- `read`   - (Optional) Timeout for read operations.
- `update` - (Optional) Timeout for update operations.
- `delete` - (Optional) Timeout for delete operations.
DESCRIPTION
}
