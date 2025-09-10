# EKS Upgrade Manager - Intelligent deployment and upgrade logic
# This module automatically decides whether to deploy fresh or upgrade incrementally

terraform {
  required_version = ">= 1.0"
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }
}

# Data source to check if EKS cluster exists
data "aws_eks_cluster" "existing" {
  count = var.cluster_name != "" ? 1 : 0
  name  = var.cluster_name
}

# Data source to get current cluster version if it exists
data "aws_eks_cluster" "current" {
  count = var.cluster_name != "" ? 1 : 0
  name  = var.cluster_name
}

# Local values for upgrade logic
locals {
  # Check if cluster exists
  cluster_exists = var.cluster_name != "" && length(data.aws_eks_cluster.existing) > 0
  
  # Get current version if cluster exists
  current_version = local.cluster_exists ? data.aws_eks_cluster.current[0].version : null
  
  # Define supported Kubernetes versions in order
  supported_versions = [
    "1.28", "1.29", "1.30", "1.31", "1.32", "1.33", "1.34"
  ]
  
  # Find current version index
  current_version_index = local.current_version != null ? index(local.supported_versions, local.current_version) : -1
  
  # Find target version index
  target_version_index = index(local.supported_versions, var.target_kubernetes_version)
  
  # Determine deployment strategy
  deployment_strategy = local.cluster_exists ? (
    local.current_version_index == -1 ? "fresh" : (
      local.target_version_index <= local.current_version_index ? "downgrade" : (
        local.target_version_index - local.current_version_index == 1 ? "single_upgrade" : "multi_upgrade"
      )
    )
  ) : "fresh"
  
  # Calculate next version for incremental upgrade
  next_version = local.deployment_strategy == "multi_upgrade" ? local.supported_versions[local.current_version_index + 1] : var.target_kubernetes_version
  
  # Determine if we should proceed with upgrade
  should_upgrade = local.deployment_strategy == "fresh" || 
                   local.deployment_strategy == "single_upgrade" || 
                   (local.deployment_strategy == "multi_upgrade" && var.auto_upgrade)
  
  # Final version to use
  final_version = local.should_upgrade ? (
    local.deployment_strategy == "multi_upgrade" ? local.next_version : var.target_kubernetes_version
  ) : local.current_version
}

# Output the upgrade plan
output "upgrade_plan" {
  description = "The upgrade plan for the EKS cluster"
  value = {
    cluster_exists        = local.cluster_exists
    current_version       = local.current_version
    target_version        = var.target_kubernetes_version
    deployment_strategy   = local.deployment_strategy
    next_version          = local.next_version
    final_version         = local.final_version
    should_upgrade        = local.should_upgrade
    upgrade_path          = local.deployment_strategy == "multi_upgrade" ? 
      slice(local.supported_versions, local.current_version_index + 1, local.target_version_index + 1) : 
      [var.target_kubernetes_version]
  }
}

# Output upgrade status
output "upgrade_status" {
  description = "Status of the upgrade process"
  value = {
    status = local.should_upgrade ? "proceeding" : "blocked"
    reason = local.deployment_strategy == "downgrade" ? "Downgrades are not supported" : (
      local.deployment_strategy == "multi_upgrade" && !var.auto_upgrade ? "Multi-version upgrade requires auto_upgrade=true" : "Ready to proceed"
    )
  }
}

# Output component versions based on final Kubernetes version
output "component_versions" {
  description = "Recommended component versions for the final Kubernetes version"
  value = {
    kubernetes_version = local.final_version
    karpenter_version = local.final_version == "1.28" ? "0.37.0" : (
      local.final_version == "1.29" ? "0.38.0" : (
        local.final_version == "1.30" ? "0.39.0" : (
          local.final_version == "1.31" ? "0.40.0" : "0.41.0"
        )
      )
    )
    aws_load_balancer_controller_version = local.final_version == "1.28" ? "1.6.2" : (
      local.final_version == "1.29" ? "1.7.0" : (
        local.final_version == "1.30" ? "1.7.1" : (
          local.final_version == "1.31" ? "1.8.0" : "1.8.1"
        )
      )
    )
    cert_manager_version = local.final_version == "1.28" ? "v1.13.2" : (
      local.final_version == "1.29" ? "v1.14.0" : (
        local.final_version == "1.30" ? "v1.15.0" : (
          local.final_version == "1.31" ? "v1.16.0" : "v1.17.0"
        )
      )
    )
    external_dns_version = local.final_version == "1.28" ? "1.13.1" : (
      local.final_version == "1.29" ? "1.14.0" : (
        local.final_version == "1.30" ? "1.15.0" : (
          local.final_version == "1.31" ? "1.16.0" : "1.17.0"
        )
      )
    )
    prometheus_version = local.final_version == "1.28" ? "55.4.0" : (
      local.final_version == "1.29" ? "56.0.0" : (
        local.final_version == "1.30" ? "57.0.0" : (
          local.final_version == "1.31" ? "58.0.0" : "59.0.0"
        )
      )
    )
    argocd_version = local.final_version == "1.28" ? "5.51.6" : (
      local.final_version == "1.29" ? "5.52.0" : (
        local.final_version == "1.30" ? "5.53.0" : (
          local.final_version == "1.31" ? "5.54.0" : "5.55.0"
        )
      )
    )
    crossplane_version = local.final_version == "1.28" ? "1.14.1" : (
      local.final_version == "1.29" ? "1.15.0" : (
        local.final_version == "1.30" ? "1.16.0" : (
          local.final_version == "1.31" ? "1.17.0" : "1.18.0"
        )
      )
    )
  }
}
