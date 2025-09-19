provider "aws" {
  region = var.region
}

module "eks" {
  source = "../../../../terraform/modules/aws/eks"

  org                = var.org
  env                = var.env
  cloud              = "aws"
  region             = var.region
  cluster_name       = var.cluster_name
  vpc_id             = var.vpc_id
  private_subnet_ids = var.private_subnet_ids
  k8s_version        = var.k8s_version
  node_group         = var.node_group
  tags               = var.tags
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
