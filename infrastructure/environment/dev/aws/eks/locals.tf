locals {
  global_config = yamldecode(file(var.global_config_path))
  env_config    = yamldecode(file(var.env_config_path))

  region = global_config.default_regions.aws

  aws_config = lookup(env_config, "aws", {})

  vpc_id             = aws_config.vpc_id
  private_subnet_ids = aws_config.private_subnet_ids
  cluster_name       = aws_config.cluster_name
}