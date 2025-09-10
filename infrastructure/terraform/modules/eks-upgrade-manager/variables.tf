# Variables for EKS Upgrade Manager

variable "cluster_name" {
  description = "Name of the existing EKS cluster (empty for fresh deployment)"
  type        = string
  default     = ""
}

variable "target_kubernetes_version" {
  description = "Target Kubernetes version to deploy or upgrade to"
  type        = string
  default     = "1.32"
}

variable "auto_upgrade" {
  description = "Whether to automatically proceed with multi-version upgrades"
  type        = bool
  default     = false
}

variable "aws_region" {
  description = "AWS region where the cluster is located"
  type        = string
  default     = "us-west-2"
}
