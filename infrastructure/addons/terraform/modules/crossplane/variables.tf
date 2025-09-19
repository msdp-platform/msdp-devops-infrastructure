# Crossplane Module Variables

variable "enabled" {
  description = "Enable or disable Crossplane deployment"
  type        = bool
  default     = true
}

variable "namespace" {
  description = "Kubernetes namespace for Crossplane"
  type        = string
  default     = "crossplane-system"
}


variable "crossplane_version" {
  description = "Crossplane application version"
  type        = string
  default     = "v2.0.2"
}

variable "installation_timeout" {
  description = "Timeout for Helm installation in seconds"
  type        = number
  default     = 600
}

# Provider configurations
variable "crossplane_providers" {
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
      version = "v1.4.0"
    }
    aws = {
      enabled = true
      version = "v1.15.0"
    }
    kubernetes = {
      enabled = true
      version = "v0.15.0"
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
