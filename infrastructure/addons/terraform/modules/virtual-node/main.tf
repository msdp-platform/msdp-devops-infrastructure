# Virtual Node (Azure Container Instances) Terraform Module
# This module manages Virtual Node using Terraform

terraform {
  required_providers {
    kubernetes = {
      source  = "hashicorp/kubernetes"
      version = "~> 2.24"
    }
  }
}

# Note: Virtual Node is typically enabled at the AKS cluster level
# This module creates a placeholder for future implementation
# For now, it just creates a ConfigMap to indicate the feature is "enabled"

resource "kubernetes_config_map" "virtual_node_config" {
  count = var.enabled ? 1 : 0
  
  metadata {
    name      = "virtual-node-config"
    namespace = "kube-system"
    
    labels = {
      "app.kubernetes.io/name"       = "virtual-node"
      "app.kubernetes.io/managed-by" = "terraform"
      "app.kubernetes.io/part-of"    = "kubernetes-addons"
    }
  }
  
  data = {
    "enabled" = "true"
    "resource_group_name" = var.resource_group_name
    "subnet_name" = var.subnet_name
    "note" = "Virtual Node is typically enabled at AKS cluster creation time. This ConfigMap indicates the feature is tracked by Terraform."
  }
}

# Output important information
output "namespace" {
  description = "The namespace where Virtual Node config is stored"
  value       = var.enabled ? "kube-system" : null
}

output "helm_release_status" {
  description = "The status of the Virtual Node (placeholder)"
  value       = var.enabled ? "deployed" : null
}

output "helm_release_version" {
  description = "The version of Virtual Node (placeholder)"
  value       = var.enabled ? "cluster-managed" : null
}