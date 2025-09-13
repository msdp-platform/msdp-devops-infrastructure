locals {
  # Remote state is the single source of truth
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

locals {
  effective_subnet_id = local.use_remote_state ? try(data.terraform_remote_state.network[0].outputs.subnets["${var.subnet_name}"].id, "") : ""
}
