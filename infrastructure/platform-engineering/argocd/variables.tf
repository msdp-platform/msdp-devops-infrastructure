# ArgoCD Terraform Variables

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
  description = "ArgoCD component configuration from platform-engineering.yaml"
  type = object({
    enabled       = bool
    namespace     = string
    chart_version = string
    app_version   = string
    repository    = string
    values        = any
  })
}

variable "namespace" {
  description = "Kubernetes namespace for ArgoCD"
  type        = string
  default     = "argocd"
}

# GitHub credentials for repository access
variable "github_username" {
  description = "GitHub username for repository access"
  type        = string
  default     = "msdp-platform"
}

variable "github_token" {
  description = "GitHub Personal Access Token for repository access"
  type        = string
  sensitive   = true
  default     = ""
}

# ArgoCD admin credentials
variable "argocd_admin_password" {
  description = "ArgoCD admin password"
  type        = string
  sensitive   = true
  default     = "msdp-admin-secure-password"
}

# Azure AD integration (future)
variable "azure_client_id" {
  description = "Azure AD Client ID for OIDC integration"
  type        = string
  sensitive   = true
  default     = ""
}

variable "azure_client_secret" {
  description = "Azure AD Client Secret for OIDC integration"
  type        = string
  sensitive   = true
  default     = ""
}

variable "azure_tenant_id" {
  description = "Azure AD Tenant ID for OIDC integration"
  type        = string
  sensitive   = true
  default     = ""
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
