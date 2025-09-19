# External DNS Terraform Module
# This module manages External DNS using Terraform + Helm Provider

terraform {
  required_providers {
    helm = {
      source  = "hashicorp/helm"
      version = "~> 2.15"
    }
    kubernetes = {
      source  = "hashicorp/kubernetes"
      version = "~> 2.24"
    }
  }
}

# Import shared versions
module "versions" {
  source = "../shared/versions"
}

# Create namespace
resource "kubernetes_namespace" "external_dns" {
  count = var.enabled ? 1 : 0
  
  metadata {
    name = var.namespace
    
    labels = {
      "app.kubernetes.io/name"       = "external-dns"
      "app.kubernetes.io/managed-by" = "terraform"
      "app.kubernetes.io/part-of"    = "kubernetes-addons"
    }
  }
}

# Use shared AWS credentials module
module "aws_credentials" {
  source = "../shared/aws-credentials"
  count  = var.enabled && var.cloud_provider == "azure" && !var.use_oidc && var.aws_access_key_id != "" ? 1 : 0

  enabled               = true
  secret_name          = "aws-credentials"
  namespace            = kubernetes_namespace.external_dns[0].metadata[0].name
  aws_access_key_id    = var.aws_access_key_id
  aws_secret_access_key = var.aws_secret_access_key
  aws_region           = var.aws_region
  secret_format        = "standard"
  
  labels = {
    "app.kubernetes.io/name"       = "external-dns"
    "app.kubernetes.io/component"  = "aws-credentials"
  }
}

# Create service account with appropriate annotations
resource "kubernetes_service_account" "external_dns" {
  count = var.enabled ? 1 : 0
  
  metadata {
    name      = "external-dns"
    namespace = kubernetes_namespace.external_dns[0].metadata[0].name
    
    annotations = var.cloud_provider == "aws" && var.aws_role_arn != "" ? {
      "eks.amazonaws.com/role-arn" = var.aws_role_arn
    } : var.cloud_provider == "azure" && var.use_oidc && var.azure_workload_identity_client_id != "" ? {
      "azure.workload.identity/client-id" = var.azure_workload_identity_client_id
    } : {}
    
    labels = {
      "app.kubernetes.io/name"       = "external-dns"
      "app.kubernetes.io/managed-by" = "terraform"
    }
  }
  
  automount_service_account_token = true
}

# Deploy External DNS using Helm
resource "helm_release" "external_dns" {
  count = var.enabled ? 1 : 0
  
  name       = "external-dns"
  repository = "https://kubernetes-sigs.github.io/external-dns/"
  chart      = "external-dns"
  version    = module.versions.chart_versions.external_dns
  namespace  = kubernetes_namespace.external_dns[0].metadata[0].name
  
  # Wait for namespace and service account
  depends_on = [
    kubernetes_namespace.external_dns,
    kubernetes_service_account.external_dns,
    module.aws_credentials
  ]
  
  values = [
    templatefile("${path.module}/values.yaml", {
      # Common configuration
      domain_filters    = jsonencode(var.domain_filters)
      txt_owner_id     = var.txt_owner_id
      policy           = var.policy
      registry         = var.registry
      txt_prefix       = var.txt_prefix
      log_level        = var.log_level
      
      # Cloud-specific configuration
      dns_provider     = var.dns_provider
      aws_region       = var.aws_region
      aws_zone_type    = var.aws_zone_type
      hosted_zone_id   = var.hosted_zone_id
      
      # Service account
      service_account_name = kubernetes_service_account.external_dns[0].metadata[0].name
      
      # Resource configuration
      replica_count    = var.replica_count
      resources        = jsonencode(var.resources)
      
      # Security configuration
      security_context = jsonencode(var.security_context)
      
      # AWS credentials (for Azure clusters)
      use_aws_credentials = var.cloud_provider == "azure" && !var.use_oidc
      aws_credentials_secret = var.cloud_provider == "azure" && !var.use_oidc && length(module.aws_credentials) > 0 ? module.aws_credentials[0].secret_name : ""
      
      # OIDC configuration
      use_oidc = var.use_oidc
      aws_role_arn = var.aws_role_arn
      aws_web_identity_token_file = var.aws_web_identity_token_file
      azure_workload_identity_client_id = var.azure_workload_identity_client_id
    })
  ]
  
  # Timeout and retry configuration
  timeout          = var.installation_timeout
  wait             = true
  wait_for_jobs    = true
  atomic           = var.atomic_installation
  cleanup_on_fail  = true
  
  # Force update if values change
  recreate_pods = true
}

# Create ClusterRole for External DNS
resource "kubernetes_cluster_role" "external_dns" {
  count = var.enabled ? 1 : 0
  
  metadata {
    name = "external-dns"
    
    labels = {
      "app.kubernetes.io/name"       = "external-dns"
      "app.kubernetes.io/managed-by" = "terraform"
    }
  }
  
  rule {
    api_groups = [""]
    resources  = ["services", "endpoints", "pods", "nodes"]
    verbs      = ["get", "watch", "list"]
  }
  
  rule {
    api_groups = ["extensions", "networking.k8s.io"]
    resources  = ["ingresses"]
    verbs      = ["get", "watch", "list"]
  }
  
  rule {
    api_groups = ["networking.istio.io"]
    resources  = ["gateways", "virtualservices"]
    verbs      = ["get", "watch", "list"]
  }
}

# Create ClusterRoleBinding
resource "kubernetes_cluster_role_binding" "external_dns" {
  count = var.enabled ? 1 : 0
  
  metadata {
    name = "external-dns"
    
    labels = {
      "app.kubernetes.io/name"       = "external-dns"
      "app.kubernetes.io/managed-by" = "terraform"
    }
  }
  
  role_ref {
    api_group = "rbac.authorization.k8s.io"
    kind      = "ClusterRole"
    name      = kubernetes_cluster_role.external_dns[0].metadata[0].name
  }
  
  subject {
    kind      = "ServiceAccount"
    name      = kubernetes_service_account.external_dns[0].metadata[0].name
    namespace = kubernetes_namespace.external_dns[0].metadata[0].name
  }
}

# Output important information
output "namespace" {
  description = "The namespace where External DNS is deployed"
  value       = var.enabled ? kubernetes_namespace.external_dns[0].metadata[0].name : null
}

output "service_account" {
  description = "The service account used by External DNS"
  value       = var.enabled ? kubernetes_service_account.external_dns[0].metadata[0].name : null
}

output "helm_release_status" {
  description = "The status of the Helm release"
  value       = var.enabled ? helm_release.external_dns[0].status : null
}

output "helm_release_version" {
  description = "The version of the deployed Helm chart"
  value       = var.enabled ? helm_release.external_dns[0].version : null
}
