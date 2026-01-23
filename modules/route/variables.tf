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

variable "resource_group_name" {
  type        = string
  description = "(Required) The name of the resource group in which the route table exists."
  nullable    = false
}

variable "route_table_name" {
  type        = string
  description = "(Required) The name of the route table to which this route belongs."
  nullable    = false
}

variable "next_hop_in_ip_address" {
  type        = string
  default     = null
  description = "(Optional) Contains the IP address packets should be forwarded to. Next hop values are only allowed in routes where the next hop type is VirtualAppliance."
}
