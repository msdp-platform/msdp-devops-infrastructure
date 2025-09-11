provider "aws" {
  region = var.region
}

resource "aws_eks_cluster" "this" {
  name     = var.cluster_name
  role_arn = null # Expect IRSA/IAM role to be attached externally

  vpc_config {
    subnet_ids = var.private_subnet_ids
  }

  version = var.k8s_version

  tags = merge(var.tags, {
    Environment = var.env
    Application = var.cluster_name
    ManagedBy   = var.org
  })
}

resource "aws_eks_node_group" "default" {
  cluster_name    = aws_eks_cluster.this.name
  node_group_name = var.node_group.name
  node_role_arn   = null # external IAM role expected
  subnet_ids      = var.private_subnet_ids

  scaling_config {
    desired_size = var.node_group.desired_size
    min_size     = var.node_group.min_size
    max_size     = var.node_group.max_size
  }

  instance_types = [var.node_group.instance_type]

  tags = merge(var.tags, {
    Environment = var.env
    NodeGroup   = var.node_group.name
  })
}

output "cluster_name" { value = aws_eks_cluster.this.name }
output "cluster_endpoint" { value = aws_eks_cluster.this.endpoint }
output "cluster_certificate_authority_data" { value = aws_eks_cluster.this.certificate_authority[0].data }

