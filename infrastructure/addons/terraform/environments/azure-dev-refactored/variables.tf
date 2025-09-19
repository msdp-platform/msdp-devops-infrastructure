# Refactored Variables with improved organization and validation

# Environment Configuration
variable "environment" {
  description = "Environment name (dev, staging, prod)"
  type        = string
  
  validation {
    condition     = contains(["dev", "staging", "prod"], var.environment)
    error_message = "Environment must be one of: dev, staging, prod."
  }
}

variable "cluster_name" {
  description = "Name of the Kubernetes cluster"
  type        = string
  
  validation {
    condition     = can(regex("^[a-z0-9-]+$", var.cluster_name))
    error_message = "Cluster name must contain only lowercase letters, numbers, and hyphens."
  }
}

variable "domain_name" {
  description = "Domain name for ingress resources"
  type        = string
  
  validation {
    condition     = can(regex("^[a-z0-9.-]+\\.[a-z]{2,}$", var.domain_name))
    error_message = "Domain name must be a valid FQDN."
  }
}

# AWS Configuration (for cross-cloud access)
variable "aws_region" {
  description = "AWS region for Route53 and other services"
  type        = string
  default     = "eu-west-1"
}

variable "hosted_zone_id" {
  description = "AWS Route53 hosted zone ID"
  type        = string
  
  validation {
    condition     = can(regex("^Z[A-Z0-9]+$", var.hosted_zone_id))
    error_message = "Hosted zone ID must be a valid Route53 zone ID."
  }
}

variable "aws_access_key_id" {
  description = "AWS access key ID for Route53 access"
  type        = string
  sensitive   = true
  
  validation {
    condition     = can(regex("^AKIA[A-Z0-9]{16}$", var.aws_access_key_id)) || var.aws_access_key_id == ""
    error_message = "AWS access key ID must be a valid format or empty."
  }
}

variable "aws_secret_access_key" {
  description = "AWS secret access key for Route53 access"
  type        = string
  sensitive   = true
}

variable "aws_role_arn_for_azure" {
  description = "AWS IAM role ARN for Azure OIDC (when using OIDC)"
  type        = string
  default     = ""
}

variable "aws_web_identity_token_file" {
  description = "Path to AWS web identity token file (when using OIDC)"
  type        = string
  default     = "/var/run/secrets/azure/tokens/azure-identity-token"
}

# Azure Configuration
variable "azure_workload_identity_client_id" {
  description = "Azure Workload Identity client ID"
  type        = string
  default     = ""
}

# Plugin Configuration with improved structure
variable "plugins" {
  description = "Configuration for Kubernetes addons"
  type = object({
    external_dns = object({
      enabled = bool
    })
    cert_manager = object({
      enabled = bool
    })
    nginx_ingress = object({
      enabled = bool
    })
    prometheus_stack = object({
      enabled = bool
    })
    argocd = object({
      enabled = bool
    })
    virtual_node = object({
      enabled = bool
    })
    crossplane = object({
      enabled = bool
    })
    backstage = object({
      enabled = bool
    })
  })
  
  default = {
    external_dns = {
      enabled = true
    }
    cert_manager = {
      enabled = true
    }
    nginx_ingress = {
      enabled = true
    }
    prometheus_stack = {
      enabled = true
    }
    argocd = {
      enabled = true
    }
    virtual_node = {
      enabled = false
    }
    crossplane = {
      enabled = false
    }
    backstage = {
      enabled = false
    }
  }
}

# Application-specific Configuration
variable "cert_manager_email" {
  description = "Email address for Let's Encrypt certificates"
  type        = string
  
  validation {
    condition     = can(regex("^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\\.[a-zA-Z]{2,}$", var.cert_manager_email))
    error_message = "Must be a valid email address."
  }
}

variable "grafana_admin_password" {
  description = "Admin password for Grafana"
  type        = string
  sensitive   = true
  default     = ""
  
  validation {
    condition     = length(var.grafana_admin_password) >= 8 || var.grafana_admin_password == ""
    error_message = "Grafana admin password must be at least 8 characters long."
  }
}
