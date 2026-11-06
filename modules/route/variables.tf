variable "address_prefix" {
  type        = string
  description = "(Required) The destination to which the route applies. Can be CIDR (such as 10.1.0.0/16) or Azure Service Tag (such as ApiManagement, AzureBackup or AzureMonitor) format."
  nullable    = false
}

variable "name" {
  type        = string
  description = "(Required) The name of the route."
  nullable    = false
}

variable "next_hop_type" {
  type        = string
  description = "(Required) The type of Azure hop the packet should be sent to. Possible values are VirtualNetworkGateway, VnetLocal, Internet, VirtualAppliance and None."
  nullable    = false

  validation {
    condition     = contains(["VirtualNetworkGateway", "VnetLocal", "Internet", "VirtualAppliance", "None"], var.next_hop_type)
    error_message = "next_hop_type must be one of 'VirtualNetworkGateway', 'VnetLocal', 'Internet', 'VirtualAppliance' or 'None'."
  }
}

variable "parent_id" {
  type        = string
  description = "(Required) The resource ID of the route table that contains the route. Changing this forces a new resource to be created."
  nullable    = false

  validation {
    condition     = can(provider::azapi::parse_resource_id("Microsoft.Network/routeTables", var.parent_id))
    error_message = "`parent_id` must be a valid route table resource ID."
  }
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
    network_route_tables_routes = optional(list(string), [])
  })
  default     = {}
  description = <<DESCRIPTION
Paths in the route's `body` whose changes the AzAPI provider ignores. Prefer Terraform's `lifecycle.ignore_changes` when the paths are static; use this variable when the paths must be derived from variables or other non-static values.

Paths use dot notation, for example `properties.nextHopIpAddress`. Configuration changes at an ignored path are **not** sent to Azure until that path is removed from the list.

Supplying a non-empty value requires Terraform 1.11 or later, because `ignore_body_changes` is a write-only argument. Changes take effect only after an apply, because the value is held in provider-private state.

- `network_route_tables_routes` - Ignored body paths for the route.
DESCRIPTION
  nullable    = false
}

variable "location" {
  type        = string
  default     = null
  description = "The Azure region for this module's resources or telemetry deployment."

  validation {
    condition     = !var.enable_telemetry || var.location != null
    error_message = "The location must not be null when telemetry is enabled."
  }
}

variable "next_hop_ip_address" {
  type        = string
  default     = null
  description = "(Optional) Contains the IP address packets should be forwarded to. Next hop values are only allowed in routes where the next hop type is VirtualAppliance."
}

variable "resource_types" {
  type = object({
    network_route_tables_routes = optional(string, "Microsoft.Network/routeTables/routes@2022-09-01")
  })
  default     = {}
  description = <<DESCRIPTION
AzAPI resource types and API versions used by the module, in `<provider>/<resource>@<api-version>` form. Each key defaults to a tested value; supply only the keys you want to override, for example to target a sovereign cloud that serves older API versions.

- `network_route_tables_routes` - The route.
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
Retry configuration applied to every `azapi` resource managed by the module. Defaults to `null` (no custom retry).

- `error_message_regex`  - (Optional) A list of regex patterns matching error messages that trigger a retry.
- `interval_seconds`     - (Optional) Initial interval between retries in seconds.
- `max_interval_seconds` - (Optional) Maximum interval between retries in seconds.

See <https://registry.terraform.io/providers/Azure/azapi/latest/docs/resources/resource#retry> for full semantics.
DESCRIPTION
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
Default per-operation timeouts applied to every `azapi` resource managed by the module. Defaults to `null` (provider defaults). Each value is a Go duration string (e.g. `30m`, `1h`).

- `create` - (Optional) Timeout for create operations.
- `read`   - (Optional) Timeout for read operations.
- `update` - (Optional) Timeout for update operations.
- `delete` - (Optional) Timeout for delete operations.
DESCRIPTION
}
