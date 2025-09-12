locals {
  use_explicit = length(var.address_space) > 0 && length(var.subnets) > 0

  normalized_address_space = local.use_explicit ? var.address_space : [var.base_cidr]

  computed_subnets = local.use_explicit ? [] : [
    for i in range(var.subnet_count) : {
      name     = length(var.subnet_names) > i ? var.subnet_names[i] : "subnet-${i + 1}"
      cidr     = cidrsubnet(var.base_cidr, var.subnet_newbits, i)
      nsg_name = var.nsg_enabled && var.nsg_prefix != "" ? "${var.nsg_prefix}-${length(var.subnet_names) > i ? var.subnet_names[i] : "subnet-${i + 1}"}" : null
    }
  ]

  effective_subnets = local.use_explicit ? var.subnets : local.computed_subnets
}
