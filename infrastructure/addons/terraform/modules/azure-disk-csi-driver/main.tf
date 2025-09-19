# Azure Disk CSI Driver Terraform Module
# This module manages Azure Disk CSI Driver using Terraform + Helm Provider

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
resource "kubernetes_namespace" "azure_disk_csi" {
  # Do not attempt to create kube-system; it already exists on all clusters
  count = var.enabled && var.namespace != "kube-system" ? 1 : 0
  
  metadata {
    name = var.namespace
    
    labels = {
      "app.kubernetes.io/name"       = "azuredisk-csi-driver"
      "app.kubernetes.io/managed-by" = "terraform"
      "app.kubernetes.io/part-of"    = "kubernetes-addons"
    }
  }
}

# Deploy Azure Disk CSI Driver using Helm
resource "helm_release" "azure_disk_csi" {
  count = var.enabled ? 1 : 0
  
  name       = "azuredisk-csi-driver"
  repository = "https://raw.githubusercontent.com/kubernetes-sigs/azuredisk-csi-driver/master/charts"
  chart      = "azuredisk-csi-driver"
  version    = module.versions.chart_versions.azure_disk_csi
  # Always deploy into the requested namespace (kube-system is pre-existing)
  namespace  = var.namespace
  
  # Ensure namespace is created first when it's not kube-system (count may be 0)
  depends_on = [kubernetes_namespace.azure_disk_csi]
  
  values = [
    templatefile("${path.module}/values.yaml", {
      # Resource configuration
      controller_resources = jsonencode(var.controller_resources)
      node_resources = jsonencode(var.node_resources)
      
      # Security configuration
      security_context = jsonencode(var.security_context)
      
      # Feature configuration
      enable_encryption = var.enable_encryption
      
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

# Create storage classes if enabled
resource "kubernetes_storage_class" "azure_disk_premium" {
  count = var.enabled && var.create_storage_classes ? 1 : 0
  
  metadata {
    name = "managed-premium"
    annotations = {
      "storageclass.kubernetes.io/is-default-class" = var.default_storage_class == "managed-premium" ? "true" : "false"
    }
    labels = {
      "app.kubernetes.io/managed-by" = "terraform"
    }
  }
  
  storage_provisioner    = "disk.csi.azure.com"
  reclaim_policy        = "Delete"
  volume_binding_mode   = "WaitForFirstConsumer"
  allow_volume_expansion = true
  
  parameters = {
    skuName = "Premium_LRS"
    kind    = "Managed"
    cachingmode = "ReadOnly"
  }
  
  depends_on = [helm_release.azure_disk_csi]
}

resource "kubernetes_storage_class" "azure_disk_standard" {
  count = var.enabled && var.create_storage_classes ? 1 : 0
  
  metadata {
    name = "managed-standard"
    annotations = {
      "storageclass.kubernetes.io/is-default-class" = var.default_storage_class == "managed-standard" ? "true" : "false"
    }
    labels = {
      "app.kubernetes.io/managed-by" = "terraform"
    }
  }
  
  storage_provisioner    = "disk.csi.azure.com"
  reclaim_policy        = "Delete"
  volume_binding_mode   = "WaitForFirstConsumer"
  allow_volume_expansion = true
  
  parameters = {
    skuName = "Standard_LRS"
    kind    = "Managed"
    cachingmode = "ReadOnly"
  }
  
  depends_on = [helm_release.azure_disk_csi]
}

# Output important information
output "namespace" {
  description = "The namespace where Azure Disk CSI Driver is deployed"
  value       = var.enabled ? kubernetes_namespace.azure_disk_csi[0].metadata[0].name : null
}

output "helm_release_status" {
  description = "The status of the Helm release"
  value       = var.enabled ? helm_release.azure_disk_csi[0].status : null
}

output "helm_release_version" {
  description = "The version of the deployed Helm chart"
  value       = var.enabled ? helm_release.azure_disk_csi[0].version : null
}

output "storage_classes" {
  description = "Created storage classes"
  value = var.enabled && var.create_storage_classes ? [
    kubernetes_storage_class.azure_disk_premium[0].metadata[0].name,
    kubernetes_storage_class.azure_disk_standard[0].metadata[0].name
  ] : []
}