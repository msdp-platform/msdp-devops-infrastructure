# Karpenter Terraform Module
# This module manages Karpenter using Terraform + Helm Provider

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

# Import shared versions
module "versions" {
  source = "../shared/versions"
}

# Data sources
data "aws_caller_identity" "current" {}
data "aws_region" "current" {}

# Local values
locals {
  account_id = data.aws_caller_identity.current.account_id
  region     = data.aws_region.current.name
}

# Create namespace
resource "kubernetes_namespace" "karpenter" {
  count = var.enabled ? 1 : 0
  
  metadata {
    name = var.namespace
    
    labels = {
      "app.kubernetes.io/name"       = "karpenter"
      "app.kubernetes.io/managed-by" = "terraform"
      "app.kubernetes.io/part-of"    = "kubernetes-addons"
    }
  }
}

# Create service account with IAM role annotation
resource "kubernetes_service_account" "karpenter" {
  count = var.enabled ? 1 : 0
  
  metadata {
    name      = "karpenter"
    namespace = kubernetes_namespace.karpenter[0].metadata[0].name
    
    annotations = {
      "eks.amazonaws.com/role-arn" = var.aws_role_arn
    }
    
    labels = {
      "app.kubernetes.io/name"       = "karpenter"
      "app.kubernetes.io/managed-by" = "terraform"
    }
  }
  
  automount_service_account_token = true
}

# Deploy Karpenter using Helm
resource "helm_release" "karpenter" {
  count = var.enabled ? 1 : 0
  
  name       = "karpenter"
  repository = "oci://public.ecr.aws/karpenter"
  chart      = "karpenter"
  version    = module.versions.chart_versions.karpenter
  namespace  = kubernetes_namespace.karpenter[0].metadata[0].name
  
  # Wait for namespace and service account
  depends_on = [
    kubernetes_namespace.karpenter,
    kubernetes_service_account.karpenter
  ]
  
  values = [
    templatefile("${path.module}/values.yaml", {
      # Cluster configuration
      cluster_name     = var.cluster_name
      cluster_endpoint = var.cluster_endpoint
      
      # Service account
      service_account_name = kubernetes_service_account.karpenter[0].metadata[0].name
      
      # Resource configuration
      resources        = jsonencode(var.resources)
      
      # Security configuration
      security_context = jsonencode(var.security_context)
      
      # Webhook configuration
      webhook_port     = var.webhook_port
      metrics_port     = var.metrics_port
      health_probe_port = var.health_probe_port
      
      # Logging
      log_level        = var.log_level
      
      # Node configuration
      interruption_queue = var.interruption_queue
      
      # Replica count
      replica_count    = var.replica_count
    })
  ]
  
  # Set values directly for complex configurations
  set {
    name  = "settings.aws.clusterName"
    value = var.cluster_name
  }
  
  set {
    name  = "settings.aws.defaultInstanceProfile"
    value = var.node_instance_profile
  }
  
  set {
    name  = "settings.aws.interruptionQueueName"
    value = var.interruption_queue
  }
  
  # Timeout and retry configuration
  timeout          = var.installation_timeout
  wait             = true
  wait_for_jobs    = true
  atomic           = var.atomic_installation
  cleanup_on_fail  = true
  
  # Force update if values change
  recreate_pods = true
}

# Create default NodePool
resource "kubernetes_manifest" "default_nodepool" {
  count = var.enabled && var.create_default_nodepool ? 1 : 0
  
  manifest = {
    apiVersion = "karpenter.sh/v1beta1"
    kind       = "NodePool"
    metadata = {
      name = "default"
      labels = {
        "app.kubernetes.io/managed-by" = "terraform"
      }
    }
    spec = {
      # Template for nodes
      template = {
        metadata = {
          labels = var.node_labels
          annotations = var.node_annotations
        }
        spec = {
          # Node requirements
          requirements = [
            {
              key      = "kubernetes.io/arch"
              operator = "In"
              values   = var.node_architectures
            },
            {
              key      = "kubernetes.io/os"
              operator = "In"
              values   = ["linux"]
            },
            {
              key      = "karpenter.sh/capacity-type"
              operator = "In"
              values   = var.capacity_types
            },
            {
              key      = "node.kubernetes.io/instance-type"
              operator = "In"
              values   = var.instance_types
            }
          ]
          
          # Node class reference
          nodeClassRef = {
            apiVersion = "karpenter.k8s.aws/v1beta1"
            kind       = "EC2NodeClass"
            name       = "default"
          }
          
          # Taints
          taints = var.node_taints
          
          # Startup taints
          startupTaints = var.startup_taints
        }
      }
      
      # Limits
      limits = {
        cpu = var.cpu_limit
      }
      
      # Disruption settings
      disruption = {
        consolidationPolicy = var.consolidation_policy
        consolidateAfter    = var.consolidate_after
        expireAfter         = var.expire_after
      }
    }
  }
  
  depends_on = [helm_release.karpenter]
}

# Create default EC2NodeClass
resource "kubernetes_manifest" "default_nodeclass" {
  count = var.enabled && var.create_default_nodepool ? 1 : 0
  
  manifest = {
    apiVersion = "karpenter.k8s.aws/v1beta1"
    kind       = "EC2NodeClass"
    metadata = {
      name = "default"
      labels = {
        "app.kubernetes.io/managed-by" = "terraform"
      }
    }
    spec = {
      # AMI configuration
      amiFamily = var.ami_family
      
      # Subnet configuration
      subnetSelectorTerms = [
        {
          tags = var.subnet_tags
        }
      ]
      
      # Security group configuration
      securityGroupSelectorTerms = [
        {
          tags = var.security_group_tags
        }
      ]
      
      # Instance profile
      instanceProfile = var.node_instance_profile
      
      # User data
      userData = var.user_data
      
      # Block device mappings
      blockDeviceMappings = [
        {
          deviceName = "/dev/xvda"
          ebs = {
            volumeSize = var.root_volume_size
            volumeType = var.root_volume_type
            encrypted  = var.root_volume_encrypted
            deleteOnTermination = true
          }
        }
      ]
      
      # Instance store policy
      instanceStorePolicy = var.instance_store_policy
      
      # Tags
      tags = merge(var.node_tags, {
        "karpenter.sh/cluster" = var.cluster_name
      })
    }
  }
  
  depends_on = [helm_release.karpenter]
}

# Output important information
output "namespace" {
  description = "The namespace where Karpenter is deployed"
  value       = var.enabled ? kubernetes_namespace.karpenter[0].metadata[0].name : null
}

output "service_account" {
  description = "The service account used by Karpenter"
  value       = var.enabled ? kubernetes_service_account.karpenter[0].metadata[0].name : null
}

output "helm_release_status" {
  description = "The status of the Helm release"
  value       = var.enabled ? helm_release.karpenter[0].status : null
}

output "helm_release_version" {
  description = "The version of the deployed Helm chart"
  value       = var.enabled ? helm_release.karpenter[0].version : null
}

output "nodepool_name" {
  description = "The name of the default NodePool"
  value       = var.enabled && var.create_default_nodepool ? "default" : null
}

output "nodeclass_name" {
  description = "The name of the default EC2NodeClass"
  value       = var.enabled && var.create_default_nodepool ? "default" : null
}