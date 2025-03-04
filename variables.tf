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
}

variable "resource_group_name" {
  type        = string
  description = "(Required) The name of the resource group in which to create the resource. Changing this forces a new resource to be created."
  nullable    = false
}

variable "bgp_route_propagation_enabled" {
  type        = bool
  default     = true
  description = "(Optional) Boolean flag which controls propagation of routes learned by BGP on that route table. Defaults to true."
}

variable "enable_telemetry" {
  type        = bool
  default     = true
  description = <<DESCRIPTION
    (Optional) This variable controls whether or not telemetry is enabled for the module.
    For more information see <https://aka.ms/avm/telemetryinfo>.
    If it is set to false, then no telemetry will be collected.
  DESCRIPTION
}

variable "lock" {
  type = object({
    kind = string
    name = optional(string, null)
  })
  default     = null
  description = <<DESCRIPTION
    (Optional) Controls the Resource Lock configuration for this resource. The following properties can be specified:

    - `kind` - (Required) The type of lock. Possible values are `\"CanNotDelete\"` and `\"ReadOnly\"`.
    - `name` - (Optional) The name of the lock. If not specified, a name will be generated based on the `kind` value. Changing this forces the creation of a new resource.
  DESCRIPTION

  validation {
    condition     = var.lock != null ? contains(["CanNotDelete", "ReadOnly"], var.lock.kind) : true
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
    principal_type                         = optional(string, null)
  }))
  default     = {}
  description = <<DESCRIPTION
    (Optional) A map of role assignments to create on this resource. The map key is deliberately arbitrary to avoid issues where map keys maybe unknown at plan time.

    - `role_definition_id_or_name` - The ID or name of the role definition to assign to the principal.
    - `principal_id` - The ID of the principal to assign the role to.
    - `description` - The description of the role assignment.
    - `skip_service_principal_aad_check` - If set to true, skips the Azure Active Directory check for the service principal in the tenant. Defaults to false.
    - `condition` - The condition which will be used to scope the role assignment.
    - `condition_version` - The version of the condition syntax. Valid values are '2.0'.

    > Note: only set `skip_service_principal_aad_check` to true if you are assigning a role to a service principal.
DESCRIPTION
  nullable    = false
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

  validation {
    condition     = length([for route in var.routes : route.name]) == length(distinct([for route in var.routes : route.name]))
    error_message = "Each route name must be unique within the route table."
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

variable "subnet_resource_ids" {
  type        = map(string)
  default     = {}
  description = <<DESCRIPTION
    (Optional) A map of string subnet ID's to associate the route table to.
    Each value in the map must be supplied in the form of an Azure resource ID: 
```yaml annotate 
/subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.Network/virtualNetworks/{vnetName}/subnets/{subnetName}
```
Example Input:
```terraform
subnet_resource_ids = {
    subnet1 = azurerm_subnet.this.id,
    subnet2 = "/subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.Network/virtualNetworks/{vnetName}/subnets/{subnetName}"
}
```
DESCRIPTION
}

# tflint-ignore: terraform_unused_declarations
variable "tags" {
  type        = map(string)
  default     = null
  description = "(Optional) Tags of the resource."
}
