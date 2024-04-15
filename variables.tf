variable "location" {
  type        = string
  description = "(Required) Specifies the supported Azure location where the resource exists. Changing this forces a new resource to be created."
  nullable    = false
}
variable "route_table_name" {
  type        = string
  description = "(Required) Specifies the name of the Route Table. Changing this forces a new resource to be created."
  nullable    = false
}

variable "resource_group_name" {
  type        = string
  description = "(Required) The name of the resource group in which to create the resource. Changing this forces a new resource to be created."
  nullable    = false
}

variable "disable_bgp_route_propagation" {
  type        = bool
  description = "(Optional) Boolean flag which controls propagation of routes learned by BGP on that route table. True means disable."
  default     = true
}

variable "routes" {
  type = list(object({
    name                   = string
    address_prefix         = string
    next_hop_type          = string
    next_hop_in_ip_address = optional(string)
  }))
  default     = null
  description = <<-EOT
 - `name` - (Required) The name of the route.
 - `address_prefix` - (Required) The destination to which the route applies. Can be CIDR (such as 10.1.0.0/16) or Azure Service Tag (such as ApiManagement, AzureBackup or AzureMonitor) format.
 - `next_hop_type` - (Required) The type of Azure hop the packet should be sent to. Possible values are VirtualNetworkGateway, VnetLocal, Internet, VirtualAppliance and None.
 - `next_hop_in_ip_address` - (Optional) Contains the IP address packets should be forwarded to. Next hop values are only allowed in routes where the next hop type is VirtualAppliance
  EOT

  validation {
    condition     = length([for route in var.routes : route.name]) == length(distinct([for route in var.routes : route.name]))
    error_message = "Each route name must be unique within the route table."
  }

  validation {
    condition     = alltrue([for route in var.routes : contains(["VirtualNetworkGateway", "VnetLocal", "Internet", "VirtualAppliance", "None"], route.next_hop_type)])
    error_message = "next_hop_type must be one of 'VirtualNetworkGateway', 'VnetLocal', 'Internet', 'VirtualAppliance' or 'None' for all routes."
  }

  validation {
    condition     = alltrue([for route in var.routes : route.next_hop_type == "VirtualAppliance" ? can(cidrnetmask("${route.next_hop_in_ip_address}/32")) == true : true])
    error_message = "The value of next_hop_in_ip_address must be a valid IP address for routes with next_hop_type 'VirtualAppliance', and must not be in cidr notaion."
  }

  validation {
    condition     = alltrue([for route in var.routes : route.next_hop_type != "VirtualAppliance" ? route.next_hop_in_ip_address == null : true])
    error_message = "If next_hop_type is not VirtualAppliance, next_hop_in_ip_address must be null."
  }
}

variable "subnets" {
  type        = list(string)
  default     = null
  description = <<-EOT
 - `subnets` - (Required) A list of subnet ID's to associate the route table to.
  EOT

  validation {
    condition     = alltrue([for subnet in var.subnets : can(regex("/subscriptions/[a-f0-9-]+/resourceGroups/[a-zA-Z0-9_-]+/providers/Microsoft.Network/virtualNetworks/[a-zA-Z0-9_-]+/subnets/[a-zA-Z0-9_-]+", subnet))])
    error_message = "All elements in the list must be in the form of an Azure subnet resource id."
  }
}

variable "tags" {
  type        = map(string)
  default     = null
  description = "(Optional) A mapping of tags to assign to the resource."
}

variable "lock" {
  type = object({
    name = optional(string, null)
    kind = optional(string, "None")
  })
  default     = {}
  description = "The lock name and level to apply to the Route Table. Default is `None`. Possible kind values are `None`, `CanNotDelete`, and `ReadOnly`."

  validation {
    condition     = contains(["None", "CanNotDelete", "ReadOnly"], var.lock.kind)
    error_message = "lock.kind must be one of 'None', 'CanNotDelete', or 'ReadOnly'."
  }
}


variable "role_assignments" {
  type = list(object({
    role_definition_id                     = optional(string, null)
    role_definition_name                   = optional(string, null)
    principal_id                           = string
    description                            = optional(string, null)
    skip_service_principal_aad_check       = optional(bool, false)
    condition                              = optional(string, null)
    condition_version                      = optional(string, null)
    delegated_managed_identity_resource_id = optional(string, null)
  }))
  default     = []
  description = <<DESCRIPTION
  A map of role assignments to create on the Route Table. The map key is deliberately arbitrary to avoid issues where map keys maybe unknown at plan time.
  
  - `role_definition_id_or_name` - (Required) The Scoped-ID of the Role Definition or the name of a built-in Role. Changing this forces a new resource to be created.
  - `principal_id` - (Required) The ID of the Principal (User, Group or Service Principal) to assign the Role Definition to. Changing this forces a new resource to be created.
  - `principal_type` - (Optional) The type of the principal_id. Possible values are User, Group and ServicePrincipal. Changing this forces a new resource to be created.
  - `description` - (Optional) The description for this Role Assignment. Changing this forces a new resource to be created.
  - `skip_service_principal_aad_check` - (Optional) If the principal_id is a newly provisioned Service Principal set this value to true to skip the Azure Active Directory check which may fail due to replication lag. This argument is only valid if the principal_id is a Service Principal identity. Defaults to false.
  - `condition` - (Optional) The condition that limits the resources that the role can be assigned to. Changing this forces a new resource to be created.
  - `condition_version` - (Optional) The version of the condition. Possible values are 1.0 or 2.0. Changing this forces a new resource to be created.
  
  > Note: only set `skip_service_principal_aad_check` to true if you are assigning a role to a service principal.
  DESCRIPTION

  validation {
    condition = alltrue([
    for role in var.role_assignments : (role.role_definition_id == null && role.role_definition_name != null) || (role.role_definition_id != null && role.role_definition_name == null)])
    error_message = ""
  }

}

variable "enable_telemetry" {
  type        = bool
  default     = true
  description = <<DESCRIPTION
This variable controls whether or not telemetry is enabled for the module.
For more information see https://aka.ms/avm/telemetryinfo.
If it is set to false, then no telemetry will be collected.
DESCRIPTION
}


variable "name" {
  type        = string
  description = "(Required) Specifies the name of the Route Table. Changing this forces a new resource to be created."
  nullable    = false

  validation {
    condition     = can(regex("TODO", var.name))
    error_message = "The name must be TODO." # TODO remove the example below once complete:
    #condition     = can(regex("^[a-z0-9]{5,50}$", var.name))
    #error_message = "The name must be between 5 and 50 characters long and can only contain lowercase letters and numbers."
  }
}

variable "resource_group_name" {
  type        = string
  description = "The resource group where the resources will be deployed."
}

variable "enable_telemetry" {
  type        = bool
  default     = true
  description = <<DESCRIPTION
This variable controls whether or not telemetry is enabled for the module.
For more information see <https://aka.ms/avm/telemetryinfo>.
If it is set to false, then no telemetry will be collected.
DESCRIPTION
}

variable "location" {
  type        = string
  default     = null
  description = "Azure region where the resource should be deployed.  If null, the location will be inferred from the resource group location."
}

variable "lock" {
  type = object({
    name = optional(string, null)
    kind = optional(string, "None")
  })
  default     = {}
  description = "The lock level to apply. Default is `None`. Possible values are `None`, `CanNotDelete`, and `ReadOnly`."
  nullable    = false

  validation {
    condition     = contains(["CanNotDelete", "ReadOnly", "None"], var.lock.kind)
    error_message = "The lock level must be one of: 'None', 'CanNotDelete', or 'ReadOnly'."
  }
}

variable "role_assignments" {
  type = map(object({
    role_definition_id_or_name             = string
    principal_id                           = string
    description                            = optional(string, null)
    skip_service_principal_aad_check       = optional(bool, false)
    condition                              = optional(string, null)
    condition_version                      = optional(string, null)
    delegated_managed_identity_resource_id = optional(string, null)
  }))
  default     = {}
  description = <<DESCRIPTION
A map of role assignments to create on this resource. The map key is deliberately arbitrary to avoid issues where map keys maybe unknown at plan time.

- `role_definition_id_or_name` - The ID or name of the role definition to assign to the principal.
- `principal_id` - The ID of the principal to assign the role to.
- `description` - The description of the role assignment.
- `skip_service_principal_aad_check` - If set to true, skips the Azure Active Directory check for the service principal in the tenant. Defaults to false.
- `condition` - The condition which will be used to scope the role assignment.
- `condition_version` - The version of the condition syntax. Valid values are '2.0'.

> Note: only set `skip_service_principal_aad_check` to true if you are assigning a role to a service principal.
DESCRIPTION
}

# tflint-ignore: terraform_unused_declarations
variable "tags" {
  type        = map(any)
  default     = {}
  description = "The map of tags to be applied to the resource"
}
