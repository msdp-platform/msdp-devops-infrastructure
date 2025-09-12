variable "org" {
  description = "Organization name for resource naming and tagging"
  type        = string
}

variable "env" {
  description = "Environment name (dev, stg, prod)"
  type        = string
}

variable "region" {
  description = "Azure region for the AKS cluster"
  type        = string
}

variable "resource_group_name" {
  description = "Name of the Azure resource group"
  type        = string
}

variable "cluster_name" {
  description = "Name of the AKS cluster"
  type        = string
}

variable "subnet_id" {
  description = "ID of the subnet for the AKS cluster"
  type        = string
}

variable "network_plugin" {
  description = "Network plugin for AKS cluster (azure or azureoverlay)"
  type        = string
  default     = "azure"
  
  validation {
    condition     = contains(["azure", "azureoverlay"], var.network_plugin)
    error_message = "Network plugin must be either 'azure' or 'azureoverlay'."
  }
}

variable "enable_oidc" {
  description = "Enable OIDC issuer and workload identity for the cluster"
  type        = bool
  default     = true
}

variable "sku_tier" {
  description = "SKU tier for the AKS cluster (Free or Standard)"
  type        = string
  default     = "Free"
  
  validation {
    condition     = contains(["Free", "Standard"], var.sku_tier)
    error_message = "SKU tier must be either 'Free' or 'Standard'."
  }
}

variable "private_cluster" {
  description = "Enable private cluster (API server not accessible from internet)"
  type        = bool
  default     = false
}

variable "k8s_version" {
  description = "Kubernetes version. If null, uses latest stable version"
  type        = string
  default     = null
}

variable "system_node" {
  description = "Configuration for the system node pool"
  type = object({
    vm_size    = string
    min_count  = number
    max_count  = number
    os_sku     = string
  })
  default = {
    vm_size    = "Standard_D2as_v5"
    min_count  = 1
    max_count  = 2
    os_sku     = "AzureLinux"
  }
}

variable "spot_node" {
  description = "Configuration for the spot node pool"
  type = object({
    enabled        = bool
    vm_size        = string
    min_count      = number
    max_count      = number
    max_price      = number
    eviction_policy = string
    taints         = list(string)
  })
  default = {
    enabled        = true
    vm_size        = "Standard_D4as_v5"
    min_count      = 0
    max_count      = 5
    max_price      = -1
    eviction_policy = "Delete"
    taints         = ["spot=true:NoSchedule"]
  }
}

variable "log_analytics" {
  description = "Configuration for Log Analytics workspace"
  type = object({
    enabled        = bool
    retention_days = number
  })
  default = {
    enabled        = true
    retention_days = 30
  }
}

variable "tags" {
  description = "Additional tags to apply to all resources"
  type        = map(string)
  default     = {}
}