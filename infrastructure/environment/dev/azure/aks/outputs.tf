output "cluster_id" {
  description = "The ID of the AKS cluster"
  value       = module.aks.cluster_id
}

output "cluster_name" {
  description = "The name of the AKS cluster"
  value       = module.aks.cluster_name
}

output "cluster_fqdn" {
  description = "The FQDN of the AKS cluster"
  value       = module.aks.cluster_fqdn
}

output "kube_config_raw" {
  description = "Raw Kubernetes config to be used by kubectl and other compatible tools"
  value       = module.aks.kube_config_raw
  sensitive   = true
}

output "kubelet_identity_object_id" {
  description = "The object ID of the kubelet identity"
  value       = module.aks.kubelet_identity_object_id
}

output "kubelet_identity_client_id" {
  description = "The client ID of the kubelet identity"
  value       = module.aks.kubelet_identity_client_id
}

output "oidc_issuer_url" {
  description = "The OIDC issuer URL for the cluster"
  value       = module.aks.oidc_issuer_url
}

output "node_resource_group" {
  description = "The name of the resource group containing the cluster's nodes"
  value       = module.aks.node_resource_group
}

output "principal_id" {
  description = "The principal ID of the system-assigned managed identity"
  value       = module.aks.principal_id
}

output "kubernetes_version" {
  description = "The Kubernetes version of the cluster"
  value       = module.aks.kubernetes_version
}

output "log_analytics_workspace_id" {
  description = "The ID of the Log Analytics workspace"
  value       = module.aks.log_analytics_workspace_id
}

output "system_node_pool_name" {
  description = "The name of the system node pool"
  value       = module.aks.system_node_pool_name
}

output "spot_node_pool_name" {
  description = "The name of the spot node pool"
  value       = module.aks.spot_node_pool_name
}
