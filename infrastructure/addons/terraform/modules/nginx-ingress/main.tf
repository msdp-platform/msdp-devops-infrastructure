# NGINX Ingress Controller Terraform Module
# This module manages NGINX Ingress Controller using Terraform + Helm Provider

terraform {
  required_providers {
    helm = {
      source  = "hashicorp/helm"
      version = "~> 2.12"
    }
    kubernetes = {
      source  = "hashicorp/kubernetes"
      version = "~> 2.24"
    }
  }
}

# Create namespace
resource "kubernetes_namespace" "nginx_ingress" {
  count = var.enabled ? 1 : 0
  
  metadata {
    name = var.namespace
    
    labels = {
      "app.kubernetes.io/name"       = "ingress-nginx"
      "app.kubernetes.io/managed-by" = "terraform"
      "app.kubernetes.io/part-of"    = "kubernetes-addons"
    }
  }
}

# Create service account
resource "kubernetes_service_account" "nginx_ingress" {
  count = var.enabled ? 1 : 0
  
  metadata {
    name      = "ingress-nginx"
    namespace = kubernetes_namespace.nginx_ingress[0].metadata[0].name
    
    labels = {
      "app.kubernetes.io/name"       = "ingress-nginx"
      "app.kubernetes.io/managed-by" = "terraform"
    }
  }
  
  automount_service_account_token = true
}

# Deploy NGINX Ingress Controller using Helm
resource "helm_release" "nginx_ingress" {
  count = var.enabled ? 1 : 0
  
  name       = "ingress-nginx"
  repository = "https://kubernetes.github.io/ingress-nginx"
  chart      = "ingress-nginx"
  version    = var.chart_version
  namespace  = kubernetes_namespace.nginx_ingress[0].metadata[0].name
  
  # Wait for namespace and service account
  depends_on = [
    kubernetes_namespace.nginx_ingress,
    kubernetes_service_account.nginx_ingress
  ]
  
  values = [
    templatefile("${path.module}/values.yaml", {
      # Service account
      service_account_name = kubernetes_service_account.nginx_ingress[0].metadata[0].name
      
      # Configuration
      replica_count = var.replica_count
      service_type  = var.service_type
      service_annotations = jsonencode(var.service_annotations)
      
      # SSL configuration
      enable_ssl_redirect = var.enable_ssl_redirect
      default_ssl_certificate = var.default_ssl_certificate
      
      # Resource configuration
      resources = jsonencode(var.resources)
      
      # Security configuration
      security_context = jsonencode(var.security_context)
      
      # Webhook configuration
      webhook_resources = jsonencode(var.webhook_resources)
      
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
  description = "The namespace where NGINX Ingress Controller is deployed"
  value       = var.enabled ? kubernetes_namespace.nginx_ingress[0].metadata[0].name : null
}

output "service_account" {
  description = "The service account used by NGINX Ingress Controller"
  value       = var.enabled ? kubernetes_service_account.nginx_ingress[0].metadata[0].name : null
}

output "helm_release_status" {
  description = "The status of the Helm release"
  value       = var.enabled ? helm_release.nginx_ingress[0].status : null
}

output "helm_release_version" {
  description = "The version of the deployed Helm chart"
  value       = var.enabled ? helm_release.nginx_ingress[0].version : null
}