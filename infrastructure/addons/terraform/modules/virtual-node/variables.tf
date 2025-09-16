# Virtual Node Terraform Module Variables

variable "enabled" {
  description = "Enable or disable Virtual Node tracking"
  type        = bool
  default     = true
}

variable "resource_group_name" {
  description = "Azure resource group name"
  type        = string
}

variable "subnet_name" {
  description = "Subnet name for virtual nodes"
  type        = string
}

variable "node_labels" {
  description = "Labels to apply to virtual nodes"
  type        = map(string)
  default     = {}
}

variable "node_taints" {
  description = "Taints to apply to virtual nodes"
  type = list(object({
    key    = string
    value  = string
    effect = string
  }))
  default = []
}