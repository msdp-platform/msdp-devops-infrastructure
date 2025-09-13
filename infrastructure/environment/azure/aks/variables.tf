variable "resource_group" {
  type        = string
  description = "Resource group for AKS"
  default     = "rg-shared-dev"
}

variable "location" {
  type        = string
  description = "Azure region"
  default     = "uksouth"
}

variable "aks_name" {
  type        = string
  description = "AKS cluster name"
  default     = "aks-dev-01"
}

variable "kubernetes_version" {
  type        = string
  description = "Kubernetes version"
  default     = "1.29.7"
}

variable "subnet_name" {
  type        = string
  description = "Name of the subnet to use for AKS nodes"
  default     = "snet-aks-dev"
}

variable "vnet_name" {
  type        = string
  description = "Name of the Virtual Network containing the subnet"
  default     = "vnet-shared-dev"
}

variable "vnet_resource_group" {
  type        = string
  description = "Resource group containing the VNet (defaults to main resource_group if not specified)"
  default     = ""
}

variable "system_node_count" {
  type        = number
  description = "System node pool count"
  default     = 1
}

variable "system_vm_size" {
  type        = string
  description = "System node pool VM size"
  default     = "Standard_B2s"
}

variable "user_vm_size" {
  type        = string
  description = "Apps node pool VM size"
  default     = "Standard_D4s_v5"
}

variable "user_min_count" {
  type        = number
  description = "Apps node pool min nodes"
  default     = 0
}

variable "user_max_count" {
  type        = number
  description = "Apps node pool max nodes"
  default     = 6
}

variable "user_spot" {
  type        = bool
  description = "Apps node pool uses Spot instances"
  default     = false
}

variable "tags" {
  type        = map(string)
  description = "Resource tags"
  default     = {}
}
