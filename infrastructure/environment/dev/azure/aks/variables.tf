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
  description = "ID of the subnet for the AKS cluster"
  type        = string
  # This should be provided via terraform.tfvars or environment variables
  # Example: "/subscriptions/xxx/resourceGroups/rg-networking-dev/providers/Microsoft.Network/virtualNetworks/vnet-dev/subnets/aks-subnet"
}

variable "tags" {
  description = "Additional tags to apply to all resources"
  type        = map(string)
  default     = {}
}
