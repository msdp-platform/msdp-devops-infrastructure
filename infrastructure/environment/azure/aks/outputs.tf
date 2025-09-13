output "cluster_id" {
  value = azurerm_kubernetes_cluster.this.id
}

output "cluster_name" {
  value = azurerm_kubernetes_cluster.this.name
}

output "fqdn" {
  value = azurerm_kubernetes_cluster.this.fqdn
}

output "kube_config_raw" {
  value     = azurerm_kubernetes_cluster.this.kube_config_raw
  sensitive = true
}

output "kubelet_identity_object_id" {
  value = azurerm_kubernetes_cluster.this.kubelet_identity[0].object_id
}

output "kubelet_identity_client_id" {
  value = azurerm_kubernetes_cluster.this.kubelet_identity[0].client_id
}

output "oidc_issuer_url" {
  value = azurerm_kubernetes_cluster.this.oidc_issuer_url
}

output "node_resource_group" {
  value = azurerm_kubernetes_cluster.this.node_resource_group
}

output "principal_id" {
  value = azurerm_kubernetes_cluster.this.identity[0].principal_id
}

output "kubernetes_version" {
  value = azurerm_kubernetes_cluster.this.kubernetes_version
}

output "system_pool_name" {
  value = azurerm_kubernetes_cluster.this.default_node_pool[0].name
}

output "apps_pool_name" {
  value = azurerm_kubernetes_cluster_node_pool.apps.name
}

