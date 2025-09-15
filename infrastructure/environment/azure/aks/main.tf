# Azure AKS Infrastructure
# Clean, modern implementation following best practices

# Data sources for existing network resources
data "azurerm_resource_group" "network" {
  name = var.network_resource_group_name
}

data "azurerm_subnet" "aks" {
  name                 = var.subnet_name
  virtual_network_name = var.vnet_name
  resource_group_name  = var.network_resource_group_name
}

# AKS Cluster
resource "azurerm_kubernetes_cluster" "main" {
  name                = var.cluster_name
  location            = data.azurerm_resource_group.network.location
  resource_group_name = data.azurerm_resource_group.network.name
  dns_prefix          = var.dns_prefix != "" ? var.dns_prefix : replace(var.cluster_name, "/[^a-z0-9]/", "")
  kubernetes_version  = var.kubernetes_version

  # Enable important features
  oidc_issuer_enabled       = true
  workload_identity_enabled = true

  # Default node pool (system)
  default_node_pool {
    name           = "system"
    vm_size        = var.system_vm_size
    vnet_subnet_id = data.azurerm_subnet.aks.id
    
    # Auto-scaling configuration for default pool
    enable_auto_scaling = true
    min_count          = var.system_node_count
    max_count          = var.system_node_count + 2
    node_count         = var.system_node_count

    # Node pool configuration
    max_pods        = var.max_pods_per_node
    os_disk_size_gb = var.os_disk_size_gb

    # Availability zones
    zones = var.availability_zones
  }

  # Identity
  identity {
    type = "SystemAssigned"
  }

  # Network profile
  network_profile {
    network_plugin    = "azure"
    network_policy    = "azure"
    load_balancer_sku = "standard"
    outbound_type     = "loadBalancer"
    dns_service_ip    = var.dns_service_ip
    service_cidr      = var.service_cidr
  }

  # Azure AD integration
  azure_active_directory_role_based_access_control {
    tenant_id              = var.tenant_id
    admin_group_object_ids = var.admin_group_object_ids
    azure_rbac_enabled     = true
  }

  # Monitoring (optional)
  dynamic "oms_agent" {
    for_each = var.log_analytics_workspace_id != null ? [1] : []
    content {
      log_analytics_workspace_id      = var.log_analytics_workspace_id
      msi_auth_for_monitoring_enabled = true
    }
  }

  # Key Vault secrets provider
  key_vault_secrets_provider {
    secret_rotation_enabled  = true
    secret_rotation_interval = "2m"
  }

  # Auto-scaler profile
  auto_scaler_profile {
    balance_similar_node_groups      = true
    expander                         = "random"
    max_graceful_termination_sec     = "600"
    max_node_provisioning_time       = "15m"
    max_unready_nodes                = 3
    max_unready_percentage           = 45
    new_pod_scale_up_delay           = "10s"
    scale_down_delay_after_add       = "10m"
    scale_down_delay_after_delete    = "10s"
    scale_down_delay_after_failure   = "3m"
    scan_interval                    = "10s"
    scale_down_unneeded              = "10m"
    scale_down_unready               = "20m"
    scale_down_utilization_threshold = "0.5"
  }

  # Lifecycle management
  lifecycle {
    ignore_changes = [
      default_node_pool[0].node_count,
      kubernetes_version
    ]
  }

  tags = var.tags
}

# User node pool for application workloads
resource "azurerm_kubernetes_cluster_node_pool" "user" {
  name                  = "user"
  kubernetes_cluster_id = azurerm_kubernetes_cluster.main.id
  vm_size               = var.user_vm_size
  
  # Node count (fixed for now, will add auto-scaling later)
  node_count = var.user_min_count

  # Node configuration
  max_pods        = var.max_pods_per_node
  os_disk_size_gb = var.os_disk_size_gb
  
  # Availability
  zones = var.availability_zones

  # Spot instances (optional)
  priority        = var.user_spot_enabled ? "Spot" : "Regular"
  eviction_policy = var.user_spot_enabled ? "Delete" : null
  spot_max_price  = var.user_spot_enabled ? var.user_spot_max_price : null

  tags = var.tags
}
