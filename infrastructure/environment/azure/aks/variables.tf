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
  description = "Subnet name used to index the Network remote state outputs (subnets[\"<name>\"])"
  default     = "snet-aks-dev"
}

variable "remote_state_bucket" {
  type        = string
  description = "S3 bucket for reading network remote state"
  default     = ""
}

variable "remote_state_region" {
  type        = string
  description = "AWS region for S3 remote state"
  default     = ""
}

variable "remote_state_dynamodb_table" {
  type        = string
  description = "DynamoDB table for state locking (remote state)"
  default     = ""
}

variable "remote_state_key" {
  type        = string
  description = "Remote state key for the network stack"
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
  default     = true
}

variable "tags" {
  type        = map(string)
  description = "Resource tags"
  default     = {}
}
