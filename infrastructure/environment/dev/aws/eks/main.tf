provider "aws" {
  region = local.region
}

module "eks" {
  source = "../../../../terraform/modules/aws/eks"

  org                = var.org
  env                = var.env
  cloud              = "aws"
  region             = local.region
  cluster_name       = local.cluster_name
  vpc_id             = local.vpc_id
  private_subnet_ids = local.private_subnet_ids
  k8s_version        = var.k8s_version
  node_group = {
    name          = var.node_group_name
    instance_type = var.node_instance_type
    desired_size  = var.node_desired
    min_size      = var.node_min
    max_size      = var.node_max
  }
  tags = var.tags
}

output "cluster_name" {
  value = module.eks.cluster_name
}

output "cluster_endpoint" {
  value = module.eks.cluster_endpoint
}

output "cluster_certificate_authority_data" {
  value = module.eks.cluster_certificate_authority_data
}
