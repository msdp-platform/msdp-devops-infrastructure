# External DNS Terraform Module Variables

variable "enabled" {
  description = "Enable or disable External DNS deployment"
  type        = bool
  default     = true
}

variable "namespace" {
  description = "Kubernetes namespace for External DNS"
  type        = string
  default     = "external-dns-system"
}


# DNS Configuration
variable "domain_filters" {
  description = "List of domains to manage"
  type        = list(string)
  default     = ["aztech-msdp.com"]
}

variable "txt_owner_id" {
  description = "Unique identifier for this External DNS instance"
  type        = string

  validation {
    condition     = can(regex("^[a-z0-9]([a-z0-9-]{0,61}[a-z0-9])?$", var.txt_owner_id))
    error_message = "TXT owner ID must be a valid DNS label (lowercase alphanumeric and hyphens, max 63 chars)."
  }
}

variable "policy" {
  description = "DNS record management policy"
  type        = string
  default     = "sync"
  
  validation {
    condition     = contains(["sync", "upsert-only"], var.policy)
    error_message = "Policy must be either 'sync' or 'upsert-only'."
  }
}

variable "registry" {
  description = "Registry type for tracking DNS records"
  type        = string
  default     = "txt"
  
  validation {
    condition     = contains(["txt", "noop"], var.registry)
    error_message = "Registry must be either 'txt' or 'noop'."
  }
}

variable "txt_prefix" {
  description = "Prefix for TXT records"
  type        = string
  default     = "external-dns-"
}

# Cloud Provider Configuration
variable "cloud_provider" {
  description = "Cloud provider (aws or azure)"
  type        = string
  
  validation {
    condition     = contains(["aws", "azure"], var.cloud_provider)
    error_message = "Cloud provider must be either 'aws' or 'azure'."
  }
}

variable "dns_provider" {
  description = "DNS provider (aws for Route53)"
  type        = string
  default     = "aws"
}

variable "aws_region" {
  description = "AWS region"
  type        = string
  default     = "eu-west-1"
}

variable "aws_zone_type" {
  description = "AWS Route53 zone type"
  type        = string
  default     = "public"
  
  validation {
    condition     = contains(["public", "private"], var.aws_zone_type)
    error_message = "AWS zone type must be either 'public' or 'private'."
  }
}

variable "hosted_zone_id" {
  description = "AWS Route53 hosted zone ID"
  type        = string
  default     = "Z0581458B5QGVNLDPESN"
}

# AWS Authentication (for cross-cloud access)
variable "aws_role_arn" {
  description = "AWS IAM role ARN for service account (EKS)"
  type        = string
  default     = ""
}

variable "aws_access_key_id" {
  description = "AWS access key ID (for Azure clusters - legacy)"
  type        = string
  default     = ""
  sensitive   = true
}

variable "aws_secret_access_key" {
  description = "AWS secret access key (for Azure clusters - legacy)"
  type        = string
  default     = ""
  sensitive   = true
}

variable "aws_web_identity_token_file" {
  description = "Path to the web identity token file for OIDC authentication"
  type        = string
  default     = ""
}

variable "use_oidc" {
  description = "Use OIDC authentication instead of static credentials"
  type        = bool
  default     = false
}

variable "azure_workload_identity_client_id" {
  description = "Azure workload identity client ID used for federated AWS access"
  type        = string
  default     = ""
}

# Application Configuration
variable "replica_count" {
  description = "Number of External DNS replicas"
  type        = number
  default     = 1
}

variable "log_level" {
  description = "Log level for External DNS"
  type        = string
  default     = "info"
  
  validation {
    condition     = contains(["debug", "info", "warn", "error"], var.log_level)
    error_message = "Log level must be one of: debug, info, warn, error."
  }
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
      cpu    = "100m"
      memory = "128Mi"
    }
    limits = {
      cpu    = "200m"
      memory = "256Mi"
    }
  }
}

variable "security_context" {
  description = "Security context for External DNS pods"
  type = object({
    runAsNonRoot             = bool
    runAsUser                = number
    readOnlyRootFilesystem   = bool
    allowPrivilegeEscalation = bool
    capabilities = object({
      drop = list(string)
    })
  })
  default = {
    runAsNonRoot             = true
    runAsUser                = 65534
    readOnlyRootFilesystem   = true
    allowPrivilegeEscalation = false
    capabilities = {
      drop = ["ALL"]
    }
  }
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

# Monitoring Configuration
variable "metrics_enabled" {
  description = "Enable Prometheus metrics"
  type        = bool
  default     = true
}

variable "metrics_port" {
  description = "Port for Prometheus metrics"
  type        = number
  default     = 7979
}

# Node Selection
variable "node_selector" {
  description = "Node selector for External DNS pods"
  type        = map(string)
  default     = {}
}

variable "tolerations" {
  description = "Tolerations for External DNS pods"
  type = list(object({
    key      = string
    operator = string
    value    = string
    effect   = string
  }))
  default = []
}

variable "affinity" {
  description = "Affinity rules for External DNS pods"
  type        = any
  default     = {}
}
