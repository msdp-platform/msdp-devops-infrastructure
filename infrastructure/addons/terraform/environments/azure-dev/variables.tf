# Azure Development Environment Variables

variable "environment" {
  description = "Environment name"
  type        = string
  default     = "dev"
}

variable "cluster_name" {
  description = "AKS cluster name"
  type        = string
  default     = "aks-msdp-dev-01"
}

variable "azure_subscription_id" {
  description = "Azure subscription ID"
  type        = string
  default     = "ecd977ed-b8df-4eb6-9cba-98397e1b2491"
}

variable "azure_tenant_id" {
  description = "Azure tenant ID"
  type        = string
}

variable "azure_resource_group" {
  description = "Azure resource group name"
  type        = string
  default     = "rg-msdp-network-dev"
}

variable "domain_name" {
  description = "Domain name for DNS management"
  type        = string
  default     = "aztech-msdp.com"
}

variable "hosted_zone_id" {
  description = "Route53 hosted zone ID (for cross-cloud DNS)"
  type        = string
  default     = "Z0581458B5QGVNLDPESN"
}

variable "cert_manager_email" {
  description = "Email address for Let's Encrypt certificates"
  type        = string
  default     = "devops@aztech-msdp.com"
}

# AWS OIDC configuration for cross-cloud DNS access
variable "aws_role_arn_for_azure" {
  description = "AWS IAM role ARN for Azure OIDC federation (Route53 access)"
  type        = string
  default     = "arn:aws:iam::319422413814:role/AzureRoute53AccessRole"
}

variable "aws_web_identity_token_file" {
  description = "Path to the web identity token file for OIDC"
  type        = string
  default     = "/var/run/secrets/azure/tokens/azure-identity-token"
}

variable "aws_region" {
  description = "AWS region for Route53 operations"
  type        = string
  default     = "eu-west-1"
}

# Azure-specific configuration
variable "virtual_node_subnet_name" {
  description = "Subnet name for virtual nodes"
  type        = string
  default     = "snet-virtual-nodes-dev"
}

# Plugin configuration
variable "plugins" {
  description = "Plugin enablement configuration"
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
    virtual_node = object({
      enabled = bool
    })
    azure_disk_csi_driver = object({
      enabled = bool
    })
    azure_file_csi_driver = object({
      enabled = bool
    })
    keda = object({
      enabled = bool
    })
    azure_keyvault_csi_driver = object({
      enabled = bool
    })
    prometheus_stack = object({
      enabled = bool
    })
    grafana = object({
      enabled = bool
    })
    fluent_bit = object({
      enabled = bool
    })
    external_secrets = object({
      enabled = bool
    })
    argocd = object({
      enabled = bool
    })
    velero = object({
      enabled = bool
    })
  })
  
  default = {
    external_dns              = { enabled = true }
    cert_manager             = { enabled = true }
    nginx_ingress            = { enabled = true }
    virtual_node             = { enabled = true }
    azure_disk_csi_driver    = { enabled = true }
    azure_file_csi_driver    = { enabled = false }
    keda                     = { enabled = true }
    azure_keyvault_csi_driver = { enabled = false }
    prometheus_stack         = { enabled = true }
    grafana                  = { enabled = true }
    fluent_bit               = { enabled = true }
    external_secrets         = { enabled = true }
    argocd                   = { enabled = false }
    velero                   = { enabled = false }
  }
}