############################
# 1) Remote state (preferred)
############################
data "terraform_remote_state" "network" {
  count   = var.use_remote_state ? 1 : 0
  backend = "s3"
  config = {
    bucket         = "<BACKEND_BUCKET_PLACEHOLDER>"
    key            = local.resolved.network_state_key
    region         = "<BACKEND_REGION_PLACEHOLDER>"
    dynamodb_table = "<BACKEND_DDB_PLACEHOLDER>"
    encrypt        = true
  }
}

locals {
  rs_subnet_id = var.use_remote_state ? try(data.terraform_remote_state.network[0].outputs.subnet_id_aks, "") : ""
}

#################################
# 2) Name-based subnet lookup
#################################
locals {
  have_names = length(trimspace(var.resource_group)) > 0
               && length(trimspace(var.vnet_name)) > 0
               && length(trimspace(var.subnet_name)) > 0
}

data "azurerm_subnet" "by_name" {
  count                = (local.rs_subnet_id == "" && local.have_names) ? 1 : 0
  name                 = var.subnet_name
  virtual_network_name = var.vnet_name
  resource_group_name  = var.resource_group
}

locals {
  name_subnet_id = (local.rs_subnet_id == "" && local.have_names) ? data.azurerm_subnet.by_name[0].id : ""
}

#################################
# 3) Tag-based discovery (strict)
#################################
data "azurerm_resources" "subnets_by_tag" {
  count               = (local.rs_subnet_id == "" && local.name_subnet_id == "" && !local.have_names) ? 1 : 0
  type                = "Microsoft.Network/virtualNetworks/subnets"
  resource_group_name = var.resource_group != "" ? var.resource_group : null

  required_tags = var.subnet_tags
}

locals {
  tag_matches   = length(data.azurerm_resources.subnets_by_tag) == 1 ? data.azurerm_resources.subnets_by_tag[0].resources : []
  tag_subnet_id = length(local.tag_matches) == 1 ? local.tag_matches[0].id : ""
}

#################################
# Selection + validation
#################################
locals {
  effective_subnet_id = coalesce(
    local.rs_subnet_id,
    local.name_subnet_id,
    local.tag_subnet_id,
    ""
  )
}

resource "null_resource" "validate_subnet" {
  lifecycle {
    precondition {
      condition     = local.effective_subnet_id != ""
      error_message = "Network prereq not satisfied: could not resolve subnet. Provide Network remote state (preferred), or set resource_group+vnet_name+subnet_name, or ensure exactly one subnet matches tags ${jsonencode(var.subnet_tags)}."
    }
  }
}

# Optional: enforce strictness for tag discovery
resource "null_resource" "validate_tag_uniqueness" {
  count = (local.rs_subnet_id == "" && local.name_subnet_id == "" && !local.have_names) ? 1 : 0
  lifecycle {
    precondition {
      condition     = length(local.tag_matches) == 1
      error_message = length(local.tag_matches) == 0 ? "No subnet found with tags ${jsonencode(var.subnet_tags)}." : "Multiple subnets match tags ${jsonencode(var.subnet_tags)}. Refine tags or use name-based lookup."
    }
  }
}

#################################
# AKS resources
#################################
resource "azurerm_kubernetes_cluster" "this" {
  name                = local.resolved.aks_name
  location            = local.resolved.location
  resource_group_name = local.resolved.resource_group
  kubernetes_version  = local.resolved.kubernetes_version
  dns_prefix          = replace(local.resolved.aks_name, "/[^a-z0-9-]/", "")

  oidc_issuer_enabled       = true
  workload_identity_enabled = true

  default_node_pool {
    name           = "system"
    vm_size        = local.resolved.system_vm
    node_count     = local.resolved.system_count
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
}

resource "azurerm_kubernetes_cluster_node_pool" "apps" {
  name                  = "apps"
  kubernetes_cluster_id = azurerm_kubernetes_cluster.this.id
  vm_size               = local.resolved.user_vm
  node_count            = local.resolved.min_count
  vnet_subnet_id        = local.effective_subnet_id
  priority              = local.resolved.user_spot ? "Spot" : "Regular"
  eviction_policy       = local.resolved.user_spot ? "Delete" : null
}

# Debug output to show which subnet was used
output "resolved_subnet_id" {
  value = local.effective_subnet_id
}
