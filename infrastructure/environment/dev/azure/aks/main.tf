# Local values for baseline tagging
locals {
  baseline_tags = {
    Org       = var.org
    Env       = var.env
    ManagedBy = "Terraform"
    Component = "AKS"
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
  subnet_id           = var.subnet_id

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
