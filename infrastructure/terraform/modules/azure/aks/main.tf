# Data source to get latest stable AKS version
data "azurerm_kubernetes_service_versions" "this" {
  location        = var.region
  include_preview = false
}

# Log Analytics workspace (optional, cost-aware)
resource "azurerm_log_analytics_workspace" "this" {
  count               = var.log_analytics.enabled ? 1 : 0
  name                = "${var.cluster_name}-logs"
  location            = var.region
  resource_group_name = var.resource_group_name
  sku                 = "PerGB2018"
  retention_in_days   = var.log_analytics.retention_days

  tags = merge(var.tags, {
    Component = "LogAnalytics"
    Purpose   = "AKS-Monitoring"
  })
}

# AKS Cluster
resource "azurerm_kubernetes_cluster" "this" {
  name                    = var.cluster_name
  location                = var.region
  resource_group_name     = var.resource_group_name
  dns_prefix              = "${var.cluster_name}-${var.env}"
  sku_tier                = var.sku_tier
  private_cluster_enabled = var.private_cluster

  # OIDC and Workload Identity
  oidc_issuer_enabled       = var.enable_oidc
  workload_identity_enabled = var.enable_oidc

  # Kubernetes version (use latest stable if not specified)
  kubernetes_version = var.k8s_version != null ? var.k8s_version : data.azurerm_kubernetes_service_versions.this.latest_version

  # System-assigned managed identity
  identity {
    type = "SystemAssigned"
  }

  # Default node pool (system nodes)
  default_node_pool {
    name                         = "system"
    vm_size                      = var.system_node.vm_size
    vnet_subnet_id               = var.subnet_id
    min_count                    = var.system_node.min_count
    max_count                    = var.system_node.max_count
    os_sku                       = var.system_node.os_sku
    only_critical_addons_enabled = true
  }

  # Network profile
  network_profile {
    network_plugin    = var.network_plugin
    load_balancer_sku = "standard"
  }

  # RBAC configuration
  role_based_access_control_enabled = true

  # Log Analytics integration (if enabled)
  dynamic "oms_agent" {
    for_each = var.log_analytics.enabled ? [1] : []
    content {
      log_analytics_workspace_id = azurerm_log_analytics_workspace.this[0].id
    }
  }

  tags = merge(var.tags, {
    Component = "AKS-Cluster"
    NodePool  = "system"
  })
}

# Spot node pool (conditional)
resource "azurerm_kubernetes_cluster_node_pool" "user_spot" {
  count                 = var.spot_node.enabled ? 1 : 0
  name                  = "spot"
  kubernetes_cluster_id = azurerm_kubernetes_cluster.this.id
  vm_size               = var.spot_node.vm_size
  vnet_subnet_id        = var.subnet_id
  mode                  = "User"
  min_count             = var.spot_node.min_count
  max_count             = var.spot_node.max_count
  priority              = "Spot"
  eviction_policy       = var.spot_node.eviction_policy
  spot_max_price        = var.spot_node.max_price
  node_taints           = var.spot_node.taints

  tags = merge(var.tags, {
    Component = "AKS-NodePool"
    NodePool  = "spot"
    Priority  = "Spot"
  })
}
