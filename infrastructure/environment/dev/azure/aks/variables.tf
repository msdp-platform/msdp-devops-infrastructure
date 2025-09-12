variable "org" {
  description = "Organization name for resource naming and tagging"
  type        = string
  default     = "msdp"
}

variable "env" {
  description = "Environment name"
  type        = string
  default     = "dev"
}

variable "region" {
  description = "Azure region for the AKS cluster"
  type        = string
  default     = "uksouth"
}

variable "resource_group_name" {
  description = "Name of the Azure resource group"
  type        = string
  default     = "rg-aks-dev"
}

variable "cluster_name" {
  description = "Name of the AKS cluster"
  type        = string
  default     = "aks-dev"
}

variable "subnet_id" {
  description = "ID of the subnet for the AKS cluster (alternative to network lookup)"
  type        = string
  default     = ""
  # Example: "/subscriptions/xxx/resourceGroups/rg-networking-dev/providers/Microsoft.Network/virtualNetworks/vnet-dev/subnets/aks-subnet"
}

variable "network_rg" {
  description = "Resource group name containing the VNet (alternative to subnet_id)"
  type        = string
  default     = ""
}

variable "vnet_name" {
  description = "Virtual network name (alternative to subnet_id)"
  type        = string
  default     = ""
}

variable "subnet_name" {
  description = "Subnet name within the VNet (alternative to subnet_id)"
  type        = string
  default     = ""
}

variable "tags" {
  description = "Additional tags to apply to all resources"
  type        = map(string)
  default     = {}
}
