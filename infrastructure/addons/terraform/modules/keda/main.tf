# KEDA Terraform Module
# This module manages KEDA using Terraform + Helm Provider

terraform {
  required_providers {
    helm = {
      source  = "hashicorp/helm"
      version = "~> 2.24"
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
resource "kubernetes_namespace" "keda" {
  count = var.enabled ? 1 : 0
  
  metadata {
    name = var.namespace
    
    labels = {
      "app.kubernetes.io/name"       = "keda"
      "app.kubernetes.io/managed-by" = "terraform"
      "app.kubernetes.io/part-of"    = "kubernetes-addons"
    }
  }
}

# Deploy KEDA using Helm
resource "helm_release" "keda" {
  count = var.enabled ? 1 : 0
  
  name       = "keda"
  repository = "https://kedacore.github.io/charts"
  chart      = "keda"
  version    = module.versions.chart_versions.keda
  namespace  = kubernetes_namespace.keda[0].metadata[0].name
  
  # Wait for namespace
  depends_on = [kubernetes_namespace.keda]
  
  values = [
    templatefile("${path.module}/values.yaml", {
      # Resource configuration
      resources = jsonencode(var.resources)
      
      # Security configuration
      security_context = jsonencode(var.security_context)
      
      # Azure configuration
      azure_subscription_id = var.azure_subscription_id
      azure_resource_group = var.azure_resource_group
      
      # Logging configuration
      log_level = var.log_level
      
      # Metrics configuration
      metrics_enabled = var.metrics_enabled
      metrics_port = var.metrics_port
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

# Output important information
output "namespace" {
  description = "The namespace where KEDA is deployed"
  value       = var.enabled ? kubernetes_namespace.keda[0].metadata[0].name : null
}

output "helm_release_status" {
  description = "The status of the Helm release"
  value       = var.enabled ? helm_release.keda[0].status : null
}

output "helm_release_version" {
  description = "The version of the deployed Helm chart"
  value       = var.enabled ? helm_release.keda[0].version : null
}