# Azure Development Environment - Terraform Variables
# This file contains environment-specific configuration for Azure dev cluster

# Environment Configuration
environment             = "dev"
cluster_name           = "aks-msdp-dev-01"
azure_subscription_id  = "ecd977ed-b8df-4eb6-9cba-98397e1b2491"
azure_tenant_id        = "a4474822-c84f-4bd1-bc35-baed17234c9f"
azure_resource_group   = "rg-aks-msdp-dev-01"
ingress_class_name      = "nginx"
prometheus_hostname    = "prometheus.dev.aztech-msdp.com"
grafana_hostname       = "grafana.dev.aztech-msdp.com"
argocd_hostname        = "argocd.dev.aztech-msdp.com"

# Domain Configuration (using AWS Route53 for cross-cloud DNS)
domain_name         = "aztech-msdp.com"
hosted_zone_id      = "Z0581458B5QGVNLDPESN"
cert_manager_email  = "devops@aztech-msdp.com"

# AWS OIDC Configuration for cross-cloud DNS access
aws_role_arn_for_azure = "arn:aws:iam::319422413814:role/AzureRoute53AccessRole"

# Azure-specific Configuration
virtual_node_subnet_name = "snet-virtual-nodes-dev"

# Plugin Configuration
plugins = {
  # Core Infrastructure
  external_dns = { enabled = true }
  cert_manager = { enabled = true }
  nginx_ingress = {
    enabled       = true
    chart_version = "4.11.3"
  }
  
  # Azure-Specific Add-ons
  virtual_node = { enabled = false }
  azure_disk_csi_driver = { enabled = false }
  azure_file_csi_driver = { enabled = false }
  keda = { enabled = true }
  azure_keyvault_csi_driver = { enabled = false }
  
  # Observability & GitOps
  prometheus_stack = { enabled = true }
  argocd          = { enabled = true }
  
  # Currently disabled modules
  fluent_bit       = { enabled = false }
  external_secrets = { enabled = false }
  velero           = { enabled = false }
}

azure_workload_identity_client_id = "07f609da-cc9f-4433-8ded-f5f3522cc175"

aws_access_key_id = "YOUR_ACCESS_KEY_ID"  # Add your access key ID locally
aws_secret_access_key = "YOUR_SECRET_ACCESS_KEY"  # Add your secret access key locally

