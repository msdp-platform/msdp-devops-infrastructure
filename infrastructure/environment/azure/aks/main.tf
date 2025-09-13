locals {
  rg_name = var.resource_group
  rg_loc  = var.location
}

# Validation is now implicit - if the subnet doesn't exist, the data source will fail with a clear error

resource "azurerm_kubernetes_cluster" "this" {
  name                = var.aks_name
  location            = local.rg_loc
  resource_group_name = local.rg_name
  dns_prefix          = replace(var.aks_name, "/[^a-z0-9-]/", "")

  oidc_issuer_enabled       = true
  workload_identity_enabled = true

  default_node_pool {
    name           = "system"
    vm_size        = var.system_vm_size
    node_count     = var.system_node_count
    vnet_subnet_id = local.final_subnet_id
  }

  identity {
    type = "SystemAssigned"
  }

  network_profile {
    network_plugin    = "azure"
    network_policy    = "azure"
    outbound_type     = "loadBalancer"
    load_balancer_sku = "standard"
  }

  lifecycle {
    ignore_changes = [default_node_pool[0].node_count]
  }
  tags = var.tags
}

resource "azurerm_kubernetes_cluster_node_pool" "apps" {
  name                  = "apps"
  kubernetes_cluster_id = azurerm_kubernetes_cluster.this.id
  vm_size               = var.user_vm_size
  node_count            = var.user_min_count
  vnet_subnet_id        = local.final_subnet_id
  priority              = var.user_spot ? "Spot" : "Regular"
  eviction_policy       = var.user_spot ? "Delete" : null
  tags                  = var.tags
}
