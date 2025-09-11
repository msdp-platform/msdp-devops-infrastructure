resource "azurerm_kubernetes_cluster" "this" {
  name                = var.cluster_name
  location            = var.region
  resource_group_name = var.resource_group_name
  dns_prefix          = replace(var.cluster_name, "_", "-")

  default_node_pool {
    name                = var.node_pool.name
    node_count          = var.node_pool.node_count
    min_count           = var.node_pool.min_count
    max_count           = var.node_pool.max_count
    vm_size             = var.node_pool.vm_size
    vnet_subnet_id      = var.subnet_id
    orchestrator_version= var.k8s_version
    auto_scaling_enabled= true
  }

  identity {
    type = "SystemAssigned"
  }

  tags = merge(var.tags, {
    Environment = var.env
    ManagedBy   = var.org
  })
}

output "cluster_name" { value = azurerm_kubernetes_cluster.this.name }
output "kube_config" { value = azurerm_kubernetes_cluster.this.kube_config_raw sensitive = true }

