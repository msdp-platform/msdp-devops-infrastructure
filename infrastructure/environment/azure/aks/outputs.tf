# Azure AKS Module Outputs

output "cluster_id" {
  description = "ID of the AKS cluster"
  value       = azurerm_kubernetes_cluster.main.id
}

output "cluster_name" {
  description = "Name of the AKS cluster"
  value       = azurerm_kubernetes_cluster.main.name
}

output "cluster_fqdn" {
  description = "FQDN of the AKS cluster"
  value       = azurerm_kubernetes_cluster.main.fqdn
}

output "cluster_endpoint" {
  description = "Endpoint of the AKS cluster"
  value       = azurerm_kubernetes_cluster.main.kube_config[0].host
  sensitive   = true
}

output "kube_config" {
  description = "Kubernetes configuration"
  value       = azurerm_kubernetes_cluster.main.kube_config_raw
  sensitive   = true
}

output "cluster_ca_certificate" {
  description = "Cluster CA certificate"
  value       = azurerm_kubernetes_cluster.main.kube_config[0].cluster_ca_certificate
  sensitive   = true
}

output "client_certificate" {
  description = "Client certificate"
  value       = azurerm_kubernetes_cluster.main.kube_config[0].client_certificate
  sensitive   = true
}

output "client_key" {
  description = "Client key"
  value       = azurerm_kubernetes_cluster.main.kube_config[0].client_key
  sensitive   = true
}

output "cluster_identity" {
  description = "Cluster managed identity"
  value = {
    principal_id = azurerm_kubernetes_cluster.main.identity[0].principal_id
    tenant_id    = azurerm_kubernetes_cluster.main.identity[0].tenant_id
  }
}

output "kubelet_identity" {
  description = "Kubelet managed identity"
  value = {
    client_id   = azurerm_kubernetes_cluster.main.kubelet_identity[0].client_id
    object_id   = azurerm_kubernetes_cluster.main.kubelet_identity[0].object_id
    user_assigned_identity_id = azurerm_kubernetes_cluster.main.kubelet_identity[0].user_assigned_identity_id
  }
}

output "oidc_issuer_url" {
  description = "OIDC issuer URL for workload identity"
  value       = azurerm_kubernetes_cluster.main.oidc_issuer_url
}

output "node_resource_group" {
  description = "Resource group containing the cluster nodes"
  value       = azurerm_kubernetes_cluster.main.node_resource_group
}

output "system_node_pool" {
  description = "System node pool details"
  value = {
    name      = azurerm_kubernetes_cluster.main.default_node_pool[0].name
    vm_size   = azurerm_kubernetes_cluster.main.default_node_pool[0].vm_size
    node_count = azurerm_kubernetes_cluster.main.default_node_pool[0].node_count
  }
}

output "user_node_pool" {
  description = "User node pool details"
  value = {
    name       = azurerm_kubernetes_cluster_node_pool.user.name
    vm_size    = azurerm_kubernetes_cluster_node_pool.user.vm_size
    min_count  = azurerm_kubernetes_cluster_node_pool.user.min_count
    max_count  = azurerm_kubernetes_cluster_node_pool.user.max_count
    node_count = azurerm_kubernetes_cluster_node_pool.user.node_count
  }
}