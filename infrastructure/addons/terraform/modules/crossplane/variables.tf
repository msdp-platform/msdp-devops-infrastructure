# Crossplane Module Variables
# Following MSDP addon patterns

variable "enabled" {
  description = "Enable Crossplane deployment"
  type        = bool
  default     = false
}

variable "environment" {
  description = "Environment name (dev, staging, prod)"
  type        = string
  default     = "dev"
}

variable "namespace" {
  description = "Kubernetes namespace for Crossplane"
  type        = string
  default     = "crossplane-system"
}

variable "chart_version" {
  description = "Crossplane Helm chart version"
  type        = string
  default     = "1.14.5"
}

variable "crossplane_version" {
  description = "Crossplane application version"
  type        = string
  default     = "v1.14.5"
}

variable "installation_timeout" {
  description = "Timeout for Helm installation in seconds"
  type        = number
  default     = 600
}

variable "resources" {
  description = "Resource requests and limits for Crossplane"
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
      memory = "256Mi"
    }
    limits = {
      cpu    = "1000m"
      memory = "1Gi"
    }
  }
}

# Provider configurations
variable "providers" {
  description = "Crossplane provider configurations"
  type = object({
    azure = object({
      enabled = bool
      version = string
    })
    aws = object({
      enabled = bool
      version = string
    })
    kubernetes = object({
      enabled = bool
      version = string
    })
  })
  default = {
    azure = {
      enabled = true
      version = "v0.21.0"
    }
    aws = {
      enabled = true
      version = "v0.44.0"
    }
    kubernetes = {
      enabled = true
      version = "v0.11.0"
    }
  }
}

# Azure credentials
variable "azure_client_id" {
  description = "Azure service principal client ID"
  type        = string
  default     = ""
  sensitive   = true
}

variable "azure_client_secret" {
  description = "Azure service principal client secret"
  type        = string
  default     = ""
  sensitive   = true
}

variable "azure_tenant_id" {
  description = "Azure tenant ID"
  type        = string
  default     = ""
  sensitive   = true
}

variable "azure_subscription_id" {
  description = "Azure subscription ID"
  type        = string
  default     = ""
  sensitive   = true
}

# AWS credentials
variable "aws_access_key_id" {
  description = "AWS access key ID"
  type        = string
  default     = ""
  sensitive   = true
}

variable "aws_secret_access_key" {
  description = "AWS secret access key"
  type        = string
  default     = ""
  sensitive   = true
}

variable "aws_region" {
  description = "AWS region"
  type        = string
  default     = "eu-west-1"
}

# MSDP-specific configurations
variable "compositions" {
  description = "List of MSDP compositions to create"
  type        = list(string)
  default = [
    "msdp-aurora-serverless",
    "msdp-azure-postgresql",
    "msdp-redis-cache",
    "msdp-storage-bucket"
  ]
}
