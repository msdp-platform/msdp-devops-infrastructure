locals {
  # Determine if remote state inputs are provided
  use_remote_state = length(trimspace(var.remote_state_bucket)) > 0 && length(trimspace(var.remote_state_region)) > 0 && length(trimspace(var.remote_state_key)) > 0
}

data "terraform_remote_state" "network" {
  count   = local.use_remote_state ? 1 : 0
  backend = "s3"
  config = {
    bucket         = var.remote_state_bucket
    key            = var.remote_state_key
    region         = var.remote_state_region
    dynamodb_table = var.remote_state_dynamodb_table
    encrypt        = true
  }
}

data "azurerm_subnet" "by_name" {
  count                = (var.subnet_id == "" && !local.use_remote_state && length(trimspace(var.subnet_name)) > 0) ? 1 : 0
  name                 = var.subnet_name
  virtual_network_name = var.vnet_name
  resource_group_name  = var.resource_group
}

locals {
  rs_subnet_id   = local.use_remote_state ? try(data.terraform_remote_state.network[0].outputs.subnets["${var.subnet_name}"].id, "") : ""
  name_subnet_id = (!local.use_remote_state && var.subnet_id == "" && length(trimspace(var.subnet_name)) > 0) ? data.azurerm_subnet.by_name[0].id : ""
}

# Tag-based discovery when neither explicit nor remote_state nor names provided
data "azurerm_resources" "subnets_by_tag" {
  count               = (var.subnet_id == "" && !local.use_remote_state && length(trimspace(var.subnet_name)) == 0) ? 1 : 0
  type                = "Microsoft.Network/virtualNetworks/subnets"
  resource_group_name = var.resource_group != "" ? var.resource_group : null
  required_tags       = var.subnet_tags
}

locals {
  tag_matches     = length(data.azurerm_resources.subnets_by_tag) == 1 ? data.azurerm_resources.subnets_by_tag[0].resources : []
  tag_subnet_id   = length(local.tag_matches) == 1 ? local.tag_matches[0].id : ""

  effective_subnet_id = coalesce(
    trimspace(var.subnet_id) != "" ? var.subnet_id : "",
    local.rs_subnet_id,
    local.name_subnet_id,
    local.tag_subnet_id,
    ""
  )
}
