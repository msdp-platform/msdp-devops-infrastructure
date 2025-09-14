# Azure AKS Module Variables

# Cluster Configuration
variable "cluster_name" {
  type        = string
  description = "Name of the AKS cluster"
}

variable "dns_prefix" {
  type        = string
  description = "DNS prefix for the cluster. If empty, cluster name will be used"
  default     = ""
}

variable "kubernetes_version" {
  type        = string
  description = "Kubernetes version"
  default     = "1.29.7"
}

# Network Configuration
variable "network_resource_group_name" {
  type        = string
  description = "Name of the resource group containing the network resources"
}

variable "vnet_name" {
  type        = string
  description = "Name of the virtual network"
}

variable "subnet_name" {
  type        = string
  description = "Name of the subnet for AKS nodes"
}

variable "service_cidr" {
  type        = string
  description = "CIDR block for Kubernetes services"
  default     = "10.100.0.0/16"
  
  validation {
    condition     = can(cidrhost(var.service_cidr, 0))
    error_message = "The service_cidr must be a valid CIDR block."
  }
}

variable "dns_service_ip" {
  type        = string
  description = "IP address for the DNS service (must be within service_cidr)"
  default     = "10.100.0.10"
}

# System Node Pool Configuration
variable "system_node_count" {
  type        = number
  description = "Number of nodes in the system node pool"
  default     = 2
  
  validation {
    condition     = var.system_node_count >= 1 && var.system_node_count <= 10
    error_message = "System node count must be between 1 and 10."
  }
}

variable "system_vm_size" {
  type        = string
  description = "VM size for system nodes"
  default     = "Standard_D2s_v3"
}

variable "system_node_labels" {
  type        = map(string)
  description = "Additional labels for system nodes"
  default     = {}
}

# User Node Pool Configuration
variable "user_vm_size" {
  type        = string
  description = "VM size for user nodes"
  default     = "Standard_D4s_v3"
}

variable "user_min_count" {
  type        = number
  description = "Minimum number of user nodes"
  default     = 1
  
  validation {
    condition     = var.user_min_count >= 0 && var.user_min_count <= 100
    error_message = "User min count must be between 0 and 100."
  }
}

variable "user_max_count" {
  type        = number
  description = "Maximum number of user nodes"
  default     = 10
  
  validation {
    condition     = var.user_max_count >= 1 && var.user_max_count <= 100
    error_message = "User max count must be between 1 and 100."
  }
}

variable "user_spot_enabled" {
  type        = bool
  description = "Enable spot instances for user node pool"
  default     = false
}

variable "user_spot_max_price" {
  type        = number
  description = "Maximum price for spot instances (-1 for market price)"
  default     = -1
}

variable "user_node_labels" {
  type        = map(string)
  description = "Additional labels for user nodes"
  default     = {}
}

variable "user_node_taints" {
  type        = list(string)
  description = "Taints for user nodes"
  default     = []
}

# Node Configuration
variable "max_pods_per_node" {
  type        = number
  description = "Maximum number of pods per node"
  default     = 30
  
  validation {
    condition     = var.max_pods_per_node >= 10 && var.max_pods_per_node <= 250
    error_message = "Max pods per node must be between 10 and 250."
  }
}

variable "os_disk_size_gb" {
  type        = number
  description = "OS disk size in GB"
  default     = 128
  
  validation {
    condition     = var.os_disk_size_gb >= 30 && var.os_disk_size_gb <= 2048
    error_message = "OS disk size must be between 30 and 2048 GB."
  }
}

variable "availability_zones" {
  type        = list(string)
  description = "Availability zones for node pools"
  default     = ["1", "2", "3"]
}

# Azure AD Configuration
variable "tenant_id" {
  type        = string
  description = "Azure AD tenant ID"
}

variable "admin_group_object_ids" {
  type        = list(string)
  description = "List of Azure AD group object IDs for cluster admins"
  default     = []
}

# Monitoring Configuration
variable "log_analytics_workspace_id" {
  type        = string
  description = "Log Analytics workspace ID for monitoring"
  default     = null
}

# Tags
variable "tags" {
  type        = map(string)
  description = "Tags to apply to all resources"
  default     = {}
}