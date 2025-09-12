# Local values for baseline tagging and subnet validation
locals {
  baseline_tags = {
    Org       = var.org
    Env       = var.env
    ManagedBy = "Terraform"
    Component = "AKS"
  }

  # Subnet input validation
  have_subnet_id  = length(trim(var.subnet_id)) > 0
  have_name_tuple = length(trim(var.network_rg)) > 0 && length(trim(var.vnet_name)) > 0 && length(trim(var.subnet_name)) > 0
}

# Validation: At least subnet_id OR (network_rg + vnet_name + subnet_name) must be provided
resource "null_resource" "validate_subnet_inputs" {
  lifecycle {
    precondition {
      condition     = local.have_subnet_id || local.have_name_tuple
      error_message = "Provide subnet_id or (network_rg + vnet_name + subnet_name)."
    }
  }
}

# Data lookup for subnet when subnet_id is not provided
data "azurerm_subnet" "aks" {
  count                = local.have_subnet_id ? 0 : 1
  name                 = var.subnet_name
  virtual_network_name = var.vnet_name
  resource_group_name  = var.network_rg

  depends_on = [null_resource.validate_subnet_inputs]
}

# Derive effective subnet ID and validate it exists
locals {
  effective_subnet_id = local.have_subnet_id ? var.subnet_id : (length(data.azurerm_subnet.aks) == 1 ? data.azurerm_subnet.aks[0].id : "")
}

# Validation: Subnet must exist
resource "null_resource" "validate_subnet_exists" {
  depends_on = [null_resource.validate_subnet_inputs]
  lifecycle {
    precondition {
      condition     = length(trim(local.effective_subnet_id)) > 0
      error_message = "AKS pre-req missing: subnet not found. Create the subnet in the networking pipeline before deploying AKS."
    }
  }
}

# AKS Module
module "aks" {
  source = "../../../../terraform/modules/azure/aks"

  org                 = var.org
  env                 = var.env
  region              = var.region
  resource_group_name = var.resource_group_name
  cluster_name        = var.cluster_name
  subnet_id           = local.effective_subnet_id

  # Cost-effective defaults for dev environment
  network_plugin  = "azureoverlay" # Reduce IP consumption
  enable_oidc     = true           # Enable for workload identity
  sku_tier        = "Free"         # Cost-effective for dev
  private_cluster = false          # Public for easier access in dev

  # Use latest stable Kubernetes version
  k8s_version = null

  # System node pool (small for dev)
  system_node = {
    vm_size   = "Standard_D2as_v5"
    min_count = 1
    max_count = 2
    os_sku    = "AzureLinux"
  }

  # Spot node pool (enabled for cost savings)
  spot_node = {
    enabled         = true
    vm_size         = "Standard_D4as_v5"
    min_count       = 0
    max_count       = 5
    max_price       = -1 # Current market price
    eviction_policy = "Delete"
    taints          = ["spot=true:NoSchedule"]
  }

  # Log Analytics (enabled with short retention for dev)
  log_analytics = {
    enabled        = true
    retention_days = 30
  }

  # Merge baseline tags with additional tags
  tags = merge(local.baseline_tags, var.tags)
}
