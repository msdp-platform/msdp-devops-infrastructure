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
  default     = "rg-aks-msdp-dev-01"
}

variable "kubeconfig_path" {
  description = "Path to kubeconfig file provided by the workflow"
  type        = string
  default     = ""
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

variable "azure_workload_identity_client_id" {
  description = "Client ID of the Azure workload identity used for AWS federation"
  type        = string
  default     = ""
}

variable "external_dns_use_oidc" {
  description = "Whether external-dns should authenticate to AWS via OIDC"
  type        = bool
  default     = false
}

variable "aws_access_key_id" {
  description = "AWS access key ID used by external-dns when OIDC is disabled"
  type        = string
  default     = ""
}

variable "aws_secret_access_key" {
  description = "AWS secret access key used by external-dns when OIDC is disabled"
  type        = string
  default     = ""
  sensitive   = true
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
    virtual_node             = { enabled = false }
    azure_disk_csi_driver    = { enabled = false }
    azure_file_csi_driver    = { enabled = false }
    keda                     = { enabled = true }
    azure_keyvault_csi_driver = { enabled = false }
    prometheus_stack         = { enabled = true }
    fluent_bit               = { enabled = false }
    external_secrets         = { enabled = false }
    argocd                   = { enabled = true }
    velero                   = { enabled = false }
  }
}

variable "ingress_class_name" {
  description = "Default ingress class name"
  type        = string
  default     = "nginx"
}

variable "prometheus_hostname" {
  description = "Hostname for Prometheus ingress"
  type        = string
  default     = ""
}

variable "grafana_hostname" {
  description = "Hostname for Grafana ingress"
  type        = string
  default     = ""
}

variable "argocd_hostname" {
  description = "Hostname for Argo CD ingress"
  type        = string
  default     = ""
}

variable "prometheus_tls_secret_name" {
  description = "TLS secret name for Prometheus"
  type        = string
  default     = "prometheus-tls"
}

variable "grafana_tls_secret_name" {
  description = "TLS secret name for Grafana"
  type        = string
  default     = "grafana-tls"
}

variable "argocd_tls_secret_name" {
  description = "TLS secret name for Argo CD"
  type        = string
  default     = "argocd-tls"
}

# Platform Engineering Variables

variable "backstage_hostname" {
  description = "Backstage ingress hostname"
  type        = string
  default     = ""
}

variable "backstage_tls_secret_name" {
  description = "TLS secret name for Backstage"
  type        = string
  default     = "backstage-tls"
}

# GitHub credentials for Backstage
variable "github_client_id" {
  description = "GitHub OAuth client ID for Backstage authentication"
  type        = string
  default     = ""
  sensitive   = true
}

variable "github_client_secret" {
  description = "GitHub OAuth client secret for Backstage authentication"
  type        = string
  default     = ""
  sensitive   = true
}

variable "github_token" {
  description = "GitHub token for Backstage to access repositories"
  type        = string
  default     = ""
  sensitive   = true
}

# Azure credentials (for Crossplane - may already exist)
variable "azure_client_id" {
  description = "Azure service principal client ID (for Crossplane)"
  type        = string
  default     = ""
  sensitive   = true
}

variable "azure_client_secret" {
  description = "Azure service principal client secret (for Crossplane)"
  type        = string
  default     = ""
  sensitive   = true
}
