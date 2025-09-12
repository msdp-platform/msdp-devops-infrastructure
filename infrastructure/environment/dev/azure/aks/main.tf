# Data source for remote state from Network stack
data "terraform_remote_state" "network" {
  backend = "azurerm"
  config = {
    resource_group_name  = local.resolved.tfstate_rg
    storage_account_name = local.resolved.tfstate_sa
    container_name       = local.resolved.tfstate_container
    key                  = local.resolved.network_state_key
  }
}

# Data source for name-based subnet lookup (fallback)
data "azurerm_subnet" "by_name" {
  count                = data.terraform_remote_state.network.outputs.subnet_id_aks == null ? 1 : 0
  name                 = "snet-aks-${var.env}"
  virtual_network_name = "vnet-shared-${var.env}"
  resource_group_name  = "rg-shared-${var.env}"
}

# Data source for tag-based subnet lookup (fallback)
data "azurerm_resources" "subnets_by_tag" {
  count               = data.terraform_remote_state.network.outputs.subnet_id_aks == null && length(data.azurerm_subnet.by_name) == 0 ? 1 : 0
  type                = "Microsoft.Network/virtualNetworks/subnets"
  resource_group_name = "rg-shared-${var.env}"

  required_tags = {
    role = "aks"
  }
}

# Data source to get subnet details for tag-based lookup
data "azurerm_subnet" "by_tag" {
  count                = length(data.azurerm_resources.subnets_by_tag) > 0 ? 1 : 0
  name                 = split("/", data.azurerm_resources.subnets_by_tag[0].resources[0].id)[10]
  virtual_network_name = split("/", data.azurerm_resources.subnets_by_tag[0].resources[0].id)[8]
  resource_group_name  = split("/", data.azurerm_resources.subnets_by_tag[0].resources[0].id)[4]
}

# Resolve effective subnet ID with priority order
locals {
  # Priority 1: Remote state output
  remote_state_subnet_id = try(data.terraform_remote_state.network.outputs.subnet_id_aks, null)

  # Priority 2: Name-based lookup
  name_based_subnet_id = length(data.azurerm_subnet.by_name) > 0 ? data.azurerm_subnet.by_name[0].id : null

  # Priority 3: Tag-based lookup
  tag_based_subnet_id = length(data.azurerm_subnet.by_tag) > 0 ? data.azurerm_subnet.by_tag[0].id : null

  # Select effective subnet ID
  effective_subnet_id = coalesce(
    local.remote_state_subnet_id,
    local.name_based_subnet_id,
    local.tag_based_subnet_id
  )

  # Count resolved subnets for validation
  resolved_subnet_count = (
    (local.remote_state_subnet_id != null ? 1 : 0) +
    (local.name_based_subnet_id != null ? 1 : 0) +
    (local.tag_based_subnet_id != null ? 1 : 0)
  )
}

# Validation: Exactly one subnet must be resolved
resource "null_resource" "validate_subnet_resolution" {
  lifecycle {
    precondition {
      condition     = local.resolved_subnet_count == 1
      error_message = "Subnet resolution failed: found ${local.resolved_subnet_count} subnets. Expected exactly 1. Check network stack deployment or subnet configuration."
    }
  }
}

# AKS Module
module "aks" {
  source = "../../../../terraform/modules/azure/aks"

  org                 = "msdp"
  env                 = var.env
  region              = local.resolved.location
  resource_group_name = local.resolved.resource_group
  cluster_name        = local.resolved.aks_name
  subnet_id           = local.effective_subnet_id

  # Cost-effective defaults for dev environment
  network_plugin  = "azureoverlay" # Reduce IP consumption
  enable_oidc     = true           # Enable for workload identity
  sku_tier        = "Free"         # Cost-effective for dev
  private_cluster = false          # Public for easier access in dev

  # Use latest stable Kubernetes version
  k8s_version = local.resolved.kubernetes_version

  # System node pool (small for dev)
  system_node = {
    vm_size   = local.resolved.system_vm
    min_count = local.resolved.system_count
    max_count = local.resolved.system_count + 1
    os_sku    = "AzureLinux"
  }

  # Spot node pool (enabled for cost savings)
  spot_node = {
    enabled         = local.resolved.user_spot
    vm_size         = local.resolved.user_vm
    min_count       = local.resolved.min_count
    max_count       = local.resolved.max_count
    max_price       = -1 # Current market price
    eviction_policy = "Delete"
    taints          = ["spot=true:NoSchedule"]
  }

  # Log Analytics (enabled with short retention for dev)
  log_analytics = {
    enabled        = true
    retention_days = 30
  }

  # Baseline tags
  tags = {
    Environment = var.env
    ManagedBy   = "Terraform"
    Component   = "AKS"
  }

  depends_on = [null_resource.validate_subnet_resolution]
}
