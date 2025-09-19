# Azure Network Module Variables

variable "resource_group_name" {
  type        = string
  description = "Name of the resource group"
}

variable "location" {
  type        = string
  description = "Azure region where resources will be created"
}

variable "vnet_name" {
  type        = string
  description = "Name of the virtual network"
}

variable "vnet_cidr" {
  type        = string
  description = "CIDR block for the virtual network"
  validation {
    condition     = can(cidrhost(var.vnet_cidr, 0))
    error_message = "The vnet_cidr must be a valid CIDR block."
  }
}

variable "subnets" {
  type = list(object({
    name                = string
    cidr                = string
    create_nsg          = optional(bool, false)
    service_endpoints   = optional(list(string), [])
    delegations         = optional(list(object({
      name    = string
      service = string
      actions = list(string)
    })), [])
    security_rules      = optional(list(object({
      name                       = string
      priority                   = number
      direction                  = string
      access                     = string
      protocol                   = string
      source_port_range          = string
      destination_port_range     = string
      source_address_prefix      = string
      destination_address_prefix = string
    })), [])
  }))
  description = "List of subnets to create"
  
  validation {
    condition = alltrue([
      for subnet in var.subnets : can(cidrhost(subnet.cidr, 0))
    ])
    error_message = "All subnet CIDRs must be valid CIDR blocks."
  }
}

variable "tags" {
  type        = map(string)
  description = "Tags to apply to all resources"
  default     = {}
}