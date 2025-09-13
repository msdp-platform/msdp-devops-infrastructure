locals {
  use_explicit = length(var.address_space) > 0 && length(var.subnets) > 0

  normalized_address_space = local.use_explicit ? var.address_space : [var.base_cidr]

  computed_subnets_default = [
    for i in range(var.subnet_count) : {
      name     = length(var.subnet_names) > i ? var.subnet_names[i] : "subnet-${i + 1}"
      cidr     = cidrsubnet(var.base_cidr, var.subnet_newbits, i)
      nsg_name = var.nsg_prefix != "" ? "${var.nsg_prefix}-${length(var.subnet_names) > i ? var.subnet_names[i] : "subnet-${i + 1}"}" : null
    }
  ]

  computed_subnets_spec = [
    for i, s in var.computed_subnets_spec : {
      name     = s.name
      cidr     = cidrsubnet(var.base_cidr, s.newbits, i)
      nsg_name = null
    }
  ]

  computed_subnets = length(var.computed_subnets_spec) > 0 ? local.computed_subnets_spec : local.computed_subnets_default

  effective_subnets = local.use_explicit ? var.subnets : local.computed_subnets

  # Effective RG/VNet helpers
  rg_name   = var.resource_group
  vnet_name = var.vnet_name
}
