# Crossplane Terraform Variables

variable "cluster_name" {
  description = "Name of the AKS cluster"
  type        = string
}

variable "environment" {
  description = "Environment (dev, staging, prod)"
  type        = string
  validation {
    condition     = contains(["dev", "staging", "prod", "sandbox"], var.environment)
    error_message = "Environment must be one of: dev, staging, prod, sandbox."
  }
}

variable "location" {
  description = "Azure region"
  type        = string
  default     = "uksouth"
}

variable "component_config" {
  description = "Component-specific configuration from platform-engineering.yaml"
  type = object({
    enabled       = bool
    namespace     = string
    chart_version = string
    repository    = string
    values        = any
    providers = object({
      azure = object({
        enabled = bool
        version = string
        config  = any
      })
      aws = object({
        enabled = bool
        version = string
        config  = any
      })
      kubernetes = object({
        enabled = bool
        version = string
      })
    })
  })
}

variable "namespace" {
  description = "Kubernetes namespace for Crossplane"
  type        = string
  default     = "crossplane-system"
}

# Azure credentials (from GitHub secrets)
variable "azure_client_id" {
  description = "Azure Service Principal Client ID"
  type        = string
  sensitive   = true
}

variable "azure_client_secret" {
  description = "Azure Service Principal Client Secret"
  type        = string
  sensitive   = true
}

variable "azure_tenant_id" {
  description = "Azure Tenant ID"
  type        = string
  sensitive   = true
}

variable "azure_subscription_id" {
  description = "Azure Subscription ID"
  type        = string
  sensitive   = true
}

# AWS credentials (from GitHub secrets)
variable "aws_access_key_id" {
  description = "AWS Access Key ID for Crossplane"
  type        = string
  sensitive   = true
  default     = ""
}

variable "aws_secret_access_key" {
  description = "AWS Secret Access Key for Crossplane"
  type        = string
  sensitive   = true
  default     = ""
}

variable "aws_region" {
  description = "AWS region for Crossplane resources"
  type        = string
  default     = "us-east-1"
}

# Resource tags following MSDP conventions
variable "tags" {
  description = "Tags to apply to all resources"
  type        = map(string)
  default = {
    Environment = "dev"
    Project     = "msdp"
    Component   = "platform-engineering"
    ManagedBy   = "terraform"
    Owner       = "platform-team"
  }
}
