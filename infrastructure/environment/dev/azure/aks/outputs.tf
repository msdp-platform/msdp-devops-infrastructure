output "cluster_id" {
  description = "The ID of the AKS cluster"
  value       = azurerm_kubernetes_cluster.this.id
}

output "cluster_name" {
  description = "The name of the AKS cluster"
  value       = azurerm_kubernetes_cluster.this.name
}

output "cluster_fqdn" {
  description = "The FQDN of the AKS cluster"
  value       = azurerm_kubernetes_cluster.this.fqdn
}

output "kube_config_raw" {
  description = "Raw Kubernetes config to be used by kubectl and other compatible tools"
  value       = azurerm_kubernetes_cluster.this.kube_config_raw
  sensitive   = true
}

output "kubelet_identity_object_id" {
  description = "The object ID of the kubelet identity"
  value       = azurerm_kubernetes_cluster.this.kubelet_identity[0].object_id
}

output "kubelet_identity_client_id" {
  description = "The client ID of the kubelet identity"
  value       = azurerm_kubernetes_cluster.this.kubelet_identity[0].client_id
}

output "oidc_issuer_url" {
  description = "The OIDC issuer URL for the cluster"
  value       = azurerm_kubernetes_cluster.this.oidc_issuer_url
}

output "node_resource_group" {
  description = "The name of the resource group containing the cluster's nodes"
  value       = azurerm_kubernetes_cluster.this.node_resource_group
}

output "principal_id" {
  description = "The principal ID of the system-assigned managed identity"
  value       = azurerm_kubernetes_cluster.this.identity[0].principal_id
}

output "kubernetes_version" {
  description = "The Kubernetes version of the cluster"
  value       = azurerm_kubernetes_cluster.this.kubernetes_version
}

output "system_node_pool_name" {
  description = "The name of the system node pool"
  value       = azurerm_kubernetes_cluster.this.default_node_pool[0].name
}

output "apps_node_pool_name" {
  description = "The name of the apps node pool"
  value       = azurerm_kubernetes_cluster_node_pool.apps.name
}

output "resolved_subnet_id" {
  description = "The resolved subnet ID used by the cluster"
  value       = local.effective_subnet_id
}