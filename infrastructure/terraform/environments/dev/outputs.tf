# Outputs for Development Environment

output "cluster_name" {
  description = "EKS cluster name"
  value       = module.eks_blueprint.cluster_name
}

output "cluster_endpoint" {
  description = "Endpoint for EKS control plane"
  value       = module.eks_blueprint.cluster_endpoint
}

output "cluster_certificate_authority_data" {
  description = "Base64 encoded certificate data required to communicate with the cluster"
  value       = module.eks_blueprint.cluster_certificate_authority_data
}

output "vpc_id" {
  description = "ID of the VPC where the cluster is deployed"
  value       = module.eks_blueprint.vpc_id
}

output "private_subnets" {
  description = "List of IDs of private subnets"
  value       = module.eks_blueprint.private_subnets
}

output "public_subnets" {
  description = "List of IDs of public subnets"
  value       = module.eks_blueprint.public_subnets
}

output "karpenter_queue_name" {
  description = "Name of the Karpenter SQS queue"
  value       = module.eks_blueprint.karpenter_queue_name
}

output "karpenter_node_instance_profile_arn" {
  description = "ARN of the Karpenter node instance profile"
  value       = module.eks_blueprint.karpenter_node_instance_profile_arn
}

# Instructions for connecting to the cluster
output "kubectl_config" {
  description = "Instructions to configure kubectl"
  value       = <<-EOT
    aws eks update-kubeconfig --region ${var.aws_region} --name ${module.eks_blueprint.cluster_name}
  EOT
}

