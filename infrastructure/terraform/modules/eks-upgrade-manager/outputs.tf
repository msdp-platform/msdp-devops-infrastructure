# Outputs for EKS Upgrade Manager

output "upgrade_plan" {
  description = "The upgrade plan for the EKS cluster"
  value       = local.upgrade_plan
}

output "upgrade_status" {
  description = "Status of the upgrade process"
  value       = local.upgrade_status
}

output "component_versions" {
  description = "Recommended component versions for the final Kubernetes version"
  value       = local.component_versions
}

output "deployment_strategy" {
  description = "The deployment strategy to use"
  value       = local.deployment_strategy
}

output "should_proceed" {
  description = "Whether the deployment should proceed"
  value       = local.should_upgrade
}

output "next_version" {
  description = "Next version to upgrade to (for multi-version upgrades)"
  value       = local.next_version
}

output "upgrade_path" {
  description = "Complete upgrade path from current to target version"
  value       = local.deployment_strategy == "multi_upgrade" ? 
    slice(local.supported_versions, local.current_version_index + 1, local.target_version_index + 1) : 
    [var.target_kubernetes_version]
}
