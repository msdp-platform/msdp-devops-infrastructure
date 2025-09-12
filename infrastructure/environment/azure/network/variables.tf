variable "resource_group" {
  type        = string
  description = "Azure resource group name"
  default     = "rg-shared-dev"
}

variable "location" {
  type        = string
  description = "Azure region"
  default     = "uksouth"
}

variable "vnet_name" {
  type        = string
  description = "Virtual network name"
  default     = "vnet-shared-dev"
}

variable "address_space" {
  type        = list(string)
  description = "Explicit VNet CIDRs (explicit mode). If empty, base_cidr mode is used."
  default     = ["10.60.0.0/16"]
  validation {
    condition     = length(var.address_space) == 0 || alltrue([for c in var.address_space : can(cidrhost(c, 0))])
    error_message = "address_space must be valid CIDR(s)."
  }
}

variable "subnets" {
  description = "Explicit subnets (explicit mode). Each: { name, cidr, nsg_name? }"
  type = list(object({
    name     = string
    cidr     = string
    nsg_name = optional(string)
  }))
  default = [
    {
      name = "snet-aks-dev"
      cidr = "10.60.1.0/24"
    }
  ]
  validation {
    condition     = length(var.subnets) == 0 || alltrue([for s in var.subnets : can(cidrhost(s.cidr, 0))])
    error_message = "subnets[*].cidr must be valid CIDR."
  }
  validation {
    condition     = length(var.address_space) == 0 || length(var.subnets) == 0 || alltrue([for s in var.subnets : anytrue([for a in var.address_space : cidrcontains(a, cidrhost(s.cidr, 0))])])
    error_message = "Each subnet CIDR must be contained within one of the VNet CIDRs in address_space."
  }
}

variable "base_cidr" {
  type        = string
  description = "Base CIDR (computed mode). Used when address_space is empty."
  default     = ""
  validation {
    condition     = var.base_cidr == "" || can(cidrhost(var.base_cidr, 0))
    error_message = "base_cidr must be a valid CIDR."
  }
}

variable "subnet_count" {
  type        = number
  description = "Number of subnets to derive (computed mode)"
  default     = 0
  validation {
    condition     = var.base_cidr == "" || var.subnet_count > 0
    error_message = "subnet_count must be > 0 when base_cidr is provided."
  }
}

variable "subnet_newbits" {
  type        = number
  description = "Number of new bits for cidrsubnet() (computed mode)"
  default     = 8
}

variable "subnet_names" {
  type        = list(string)
  description = "Subnet names (computed mode). If fewer than subnet_count, remaining are auto-named."
  default     = []
}

variable "nsg_enabled" {
  type        = bool
  description = "When true (computed mode), generate NSG names using nsg_prefix"
  default     = false
}

variable "nsg_prefix" {
  type        = string
  description = "Prefix for NSG names in computed mode (e.g., nsg-prd). Ignored if nsg_enabled=false."
  default     = ""
}

variable "tags" {
  type        = map(string)
  description = "Resource tags"
  default     = {}
}

