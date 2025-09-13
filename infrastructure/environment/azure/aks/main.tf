resource "azurerm_resource_group" "rg" {
  count    = var.manage_resource_group ? 1 : 0
  name     = var.resource_group
  location = var.location
  tags     = var.tags
}

data "azurerm_resource_group" "rg" {
  count = var.manage_resource_group ? 0 : 1
  name  = var.resource_group
}

locals {
  rg_name = var.manage_resource_group ? azurerm_resource_group.rg[0].name : data.azurerm_resource_group.rg[0].name
  rg_loc  = var.manage_resource_group ? azurerm_resource_group.rg[0].location : data.azurerm_resource_group.rg[0].location
}

resource "null_resource" "validate_subnet" {
  lifecycle {
    precondition {
      condition     = local.effective_subnet_id != ""
      error_message = "Could not resolve subnet. Set subnet_id explicitly, or provide remote state inputs (bucket, region, key), or vnet_name+subnet_name in resource_group."
    }
  }
}

resource "azurerm_kubernetes_cluster" "this" {
  name                = var.aks_name
  location            = local.rg_loc
  resource_group_name = local.rg_name
  kubernetes_version  = var.kubernetes_version
  dns_prefix          = replace(var.aks_name, "/[^a-z0-9-]/", "")

  oidc_issuer_enabled       = true
  workload_identity_enabled = true

  default_node_pool {
    name           = "system"
    vm_size        = var.system_vm_size
    node_count     = var.system_node_count
    vnet_subnet_id = local.effective_subnet_id
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
  vnet_subnet_id        = local.effective_subnet_id
  priority              = var.user_spot ? "Spot" : "Regular"
  eviction_policy       = var.user_spot ? "Delete" : null
  tags                  = var.tags
}

