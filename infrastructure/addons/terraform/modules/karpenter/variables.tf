# Karpenter Terraform Module Variables

variable "enabled" {
  description = "Enable or disable Karpenter deployment"
  type        = bool
  default     = true
}

variable "namespace" {
  description = "Kubernetes namespace for Karpenter"
  type        = string
  default     = "karpenter"
}

variable "chart_version" {
  description = "Version of the Karpenter Helm chart"
  type        = string
  default     = "v0.32.1"
}

# Cluster Configuration
variable "cluster_name" {
  description = "EKS cluster name"
  type        = string
}

variable "cluster_endpoint" {
  description = "EKS cluster endpoint"
  type        = string
  default     = ""
}

variable "aws_role_arn" {
  description = "AWS IAM role ARN for Karpenter service account"
  type        = string
}

variable "node_instance_profile" {
  description = "EC2 instance profile for Karpenter nodes"
  type        = string
}

variable "interruption_queue" {
  description = "SQS queue name for spot interruption handling"
  type        = string
  default     = ""
}

# Application Configuration
variable "replica_count" {
  description = "Number of Karpenter controller replicas"
  type        = number
  default     = 2
}

variable "log_level" {
  description = "Log level for Karpenter"
  type        = string
  default     = "info"
  
  validation {
    condition     = contains(["debug", "info", "warn", "error"], var.log_level)
    error_message = "Log level must be one of: debug, info, warn, error."
  }
}

variable "webhook_port" {
  description = "Port for Karpenter webhook"
  type        = number
  default     = 8443
}

variable "metrics_port" {
  description = "Port for Karpenter metrics"
  type        = number
  default     = 8000
}

variable "health_probe_port" {
  description = "Port for Karpenter health probes"
  type        = number
  default     = 8081
}

variable "resources" {
  description = "Resource requests and limits"
  type = object({
    requests = object({
      cpu    = string
      memory = string
    })
    limits = object({
      cpu    = string
      memory = string
    })
  })
  default = {
    requests = {
      cpu    = "1000m"
      memory = "1Gi"
    }
    limits = {
      cpu    = "1000m"
      memory = "1Gi"
    }
  }
}

variable "security_context" {
  description = "Security context for Karpenter pods"
  type = object({
    runAsNonRoot             = bool
    runAsUser                = number
    runAsGroup               = number
    readOnlyRootFilesystem   = bool
    allowPrivilegeEscalation = bool
    capabilities = object({
      drop = list(string)
    })
  })
  default = {
    runAsNonRoot             = true
    runAsUser                = 65536
    runAsGroup               = 65536
    readOnlyRootFilesystem   = true
    allowPrivilegeEscalation = false
    capabilities = {
      drop = ["ALL"]
    }
  }
}

# NodePool Configuration
variable "create_default_nodepool" {
  description = "Create a default NodePool"
  type        = bool
  default     = true
}

variable "instance_types" {
  description = "List of instance types for Karpenter nodes"
  type        = list(string)
  default     = ["m5.large", "m5.xlarge", "m5.2xlarge", "c5.large", "c5.xlarge", "c5.2xlarge"]
}

variable "capacity_types" {
  description = "List of capacity types (on-demand, spot)"
  type        = list(string)
  default     = ["spot", "on-demand"]
}

variable "node_architectures" {
  description = "List of node architectures"
  type        = list(string)
  default     = ["amd64"]
}

variable "ami_family" {
  description = "AMI family for nodes"
  type        = string
  default     = "AL2"
  
  validation {
    condition     = contains(["AL2", "Bottlerocket", "Ubuntu"], var.ami_family)
    error_message = "AMI family must be one of: AL2, Bottlerocket, Ubuntu."
  }
}

# Node Configuration
variable "node_labels" {
  description = "Labels to apply to Karpenter nodes"
  type        = map(string)
  default = {
    "karpenter.sh/provisioner-name" = "default"
  }
}

variable "node_annotations" {
  description = "Annotations to apply to Karpenter nodes"
  type        = map(string)
  default     = {}
}

variable "node_taints" {
  description = "Taints to apply to Karpenter nodes"
  type = list(object({
    key    = string
    value  = string
    effect = string
  }))
  default = []
}

variable "startup_taints" {
  description = "Startup taints to apply to Karpenter nodes"
  type = list(object({
    key    = string
    value  = string
    effect = string
  }))
  default = []
}

variable "node_tags" {
  description = "Tags to apply to Karpenter EC2 instances"
  type        = map(string)
  default     = {}
}

# Limits and Disruption
variable "cpu_limit" {
  description = "CPU limit for the NodePool"
  type        = string
  default     = "1000"
}

variable "consolidation_policy" {
  description = "Consolidation policy for nodes"
  type        = string
  default     = "WhenUnderutilized"
  
  validation {
    condition     = contains(["WhenEmpty", "WhenUnderutilized"], var.consolidation_policy)
    error_message = "Consolidation policy must be either 'WhenEmpty' or 'WhenUnderutilized'."
  }
}

variable "consolidate_after" {
  description = "Time to wait before consolidating nodes"
  type        = string
  default     = "30s"
}

variable "expire_after" {
  description = "Time to wait before expiring nodes"
  type        = string
  default     = "2160h" # 90 days
}

# Subnet and Security Group Configuration
variable "subnet_tags" {
  description = "Tags to select subnets for Karpenter nodes"
  type        = map(string)
  default = {
    "karpenter.sh/discovery" = ""
  }
}

variable "security_group_tags" {
  description = "Tags to select security groups for Karpenter nodes"
  type        = map(string)
  default = {
    "karpenter.sh/discovery" = ""
  }
}

# Storage Configuration
variable "root_volume_size" {
  description = "Root volume size in GB"
  type        = number
  default     = 20
}

variable "root_volume_type" {
  description = "Root volume type"
  type        = string
  default     = "gp3"
  
  validation {
    condition     = contains(["gp2", "gp3", "io1", "io2"], var.root_volume_type)
    error_message = "Root volume type must be one of: gp2, gp3, io1, io2."
  }
}

variable "root_volume_encrypted" {
  description = "Enable root volume encryption"
  type        = bool
  default     = true
}

variable "instance_store_policy" {
  description = "Instance store policy"
  type        = string
  default     = "NVME"
  
  validation {
    condition     = contains(["NVME", "RAID0"], var.instance_store_policy)
    error_message = "Instance store policy must be either 'NVME' or 'RAID0'."
  }
}

variable "user_data" {
  description = "User data script for nodes"
  type        = string
  default     = ""
}

# Installation Configuration
variable "installation_timeout" {
  description = "Timeout for Helm installation in seconds"
  type        = number
  default     = 600
}

variable "atomic_installation" {
  description = "Enable atomic installation (rollback on failure)"
  type        = bool
  default     = true
}

# Node Selection
variable "node_selector" {
  description = "Node selector for Karpenter pods"
  type        = map(string)
  default     = {}
}

variable "tolerations" {
  description = "Tolerations for Karpenter pods"
  type = list(object({
    key      = string
    operator = string
    value    = string
    effect   = string
  }))
  default = []
}

variable "affinity" {
  description = "Affinity rules for Karpenter pods"
  type        = any
  default     = {}
}