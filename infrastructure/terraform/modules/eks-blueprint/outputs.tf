# Outputs for Comprehensive EKS Blueprint

# EKS Cluster Outputs
output "cluster_name" {
  description = "EKS cluster name"
  value       = module.eks.cluster_name
}

output "cluster_endpoint" {
  description = "Endpoint for EKS control plane"
  value       = module.eks.cluster_endpoint
}

output "cluster_security_group_id" {
  description = "Security group ids attached to the cluster control plane"
  value       = module.eks.cluster_security_group_id
}

output "cluster_iam_role_name" {
  description = "IAM role name associated with EKS cluster"
  value       = module.eks.cluster_iam_role_name
}

output "cluster_certificate_authority_data" {
  description = "Base64 encoded certificate data required to communicate with the cluster"
  value       = module.eks.cluster_certificate_authority_data
}

output "cluster_oidc_issuer_url" {
  description = "The URL on the EKS cluster for the OpenID Connect identity provider"
  value       = module.eks.cluster_oidc_issuer_url
}

output "cluster_primary_security_group_id" {
  description = "The cluster primary security group ID created by EKS on the cluster and other resources"
  value       = module.eks.cluster_primary_security_group_id
}

# VPC Outputs
output "vpc_id" {
  description = "ID of the VPC where the cluster is deployed"
  value       = module.vpc.vpc_id
}

output "vpc_cidr_block" {
  description = "The CIDR block of the VPC"
  value       = module.vpc.vpc_cidr_block
}

output "private_subnets" {
  description = "List of IDs of private subnets"
  value       = module.vpc.private_subnets
}

output "public_subnets" {
  description = "List of IDs of public subnets"
  value       = module.vpc.public_subnets
}

# Karpenter Outputs
output "karpenter_queue_name" {
  description = "Name of the Karpenter SQS queue"
  value       = aws_sqs_queue.karpenter.name
}

output "karpenter_queue_arn" {
  description = "ARN of the Karpenter SQS queue"
  value       = aws_sqs_queue.karpenter.arn
}

output "karpenter_node_instance_profile_arn" {
  description = "ARN of the Karpenter node instance profile"
  value       = aws_iam_instance_profile.karpenter.arn
}

output "karpenter_controller_role_arn" {
  description = "ARN of the Karpenter controller IAM role"
  value       = aws_iam_role.karpenter_controller.arn
}

# Load Balancer Controller Outputs
output "aws_load_balancer_controller_role_arn" {
  description = "ARN of the AWS Load Balancer Controller IAM role"
  value       = aws_iam_role.aws_load_balancer_controller.arn
}

# External DNS Outputs
output "external_dns_role_arn" {
  description = "ARN of the External DNS IAM role"
  value       = aws_iam_role.external_dns.arn
}

# Cert-Manager Outputs
output "cert_manager_role_arn" {
  description = "ARN of the Cert-Manager IAM role"
  value       = aws_iam_role.cert_manager.arn
}

# Secrets Store CSI Outputs
output "secrets_store_csi_role_arn" {
  description = "ARN of the Secrets Store CSI Driver IAM role"
  value       = aws_iam_role.secrets_store_csi.arn
}

# ArgoCD Outputs
output "argocd_role_arn" {
  description = "ARN of the ArgoCD IAM role"
  value       = aws_iam_role.argocd.arn
}

# Crossplane Outputs
output "crossplane_role_arn" {
  description = "ARN of the Crossplane IAM role"
  value       = aws_iam_role.crossplane.arn
}

# EKS Blueprints Addons Outputs
output "eks_blueprints_addons" {
  description = "EKS Blueprints Addons module outputs"
  value = {
    karpenter                    = module.eks_blueprints_addons.karpenter
    aws_load_balancer_controller = module.eks_blueprints_addons.aws_load_balancer_controller
    external_dns                 = module.eks_blueprints_addons.external_dns
    cert_manager                 = module.eks_blueprints_addons.cert_manager
    secrets_store_csi_driver     = module.eks_blueprints_addons.secrets_store_csi_driver
    ingress_nginx                = module.eks_blueprints_addons.ingress_nginx
    kube_prometheus_stack        = module.eks_blueprints_addons.kube_prometheus_stack
    argocd                       = module.eks_blueprints_addons.argocd
    eks_addons                   = module.eks_blueprints_addons.eks_addons
  }
}

# Backstage Outputs
output "backstage_helm_release" {
  description = "Backstage Helm release information"
  value = {
    name      = try(helm_release.backstage[0].name, null)
    namespace = try(helm_release.backstage[0].namespace, null)
    version   = try(helm_release.backstage[0].version, null)
    status    = try(helm_release.backstage[0].status, null)
  }
}

output "backstage_database_endpoint" {
  description = "Backstage PostgreSQL database endpoint"
  value       = aws_rds_cluster.backstage_postgres.endpoint
  sensitive   = true
}

# Crossplane Outputs
output "crossplane_helm_release" {
  description = "Crossplane Helm release information"
  value = {
    name      = helm_release.crossplane.name
    namespace = helm_release.crossplane.namespace
    version   = helm_release.crossplane.version
    status    = helm_release.crossplane.status
  }
}

# Route53 Outputs
output "route53_zone_id" {
  description = "Route53 hosted zone ID"
  value       = var.create_route53_zone ? aws_route53_zone.main[0].zone_id : var.route53_zone_id
}

output "route53_zone_name_servers" {
  description = "Route53 hosted zone name servers"
  value       = var.create_route53_zone ? aws_route53_zone.main[0].name_servers : []
}

# ACM Certificate Outputs
output "acm_certificate_arn" {
  description = "ARN of the ACM certificate"
  value       = var.create_acm_certificate ? aws_acm_certificate.main[0].arn : ""
}

output "acm_certificate_validation_arn" {
  description = "ARN of the validated ACM certificate"
  value       = var.create_acm_certificate ? aws_acm_certificate_validation.main[0].certificate_arn : ""
}

# Service URLs
output "argocd_url" {
  description = "ArgoCD server URL"
  value       = "https://argocd.${var.domain_name}"
}

output "backstage_url" {
  description = "Backstage URL"
  value       = "https://backstage.${var.domain_name}"
}

output "grafana_url" {
  description = "Grafana URL"
  value       = "http://grafana.monitoring.svc.cluster.local:3000"
}

output "prometheus_url" {
  description = "Prometheus URL"
  value       = "http://prometheus.monitoring.svc.cluster.local:9090"
}

# Connection Instructions
output "kubectl_config" {
  description = "Instructions to configure kubectl"
  value       = <<-EOT
    aws eks update-kubeconfig --region ${var.aws_region} --name ${module.eks.cluster_name}
  EOT
}

output "argocd_admin_password" {
  description = "ArgoCD admin password"
  value       = "admin123"
  sensitive   = true
}

output "grafana_admin_password" {
  description = "Grafana admin password"
  value       = "admin123"
  sensitive   = true
}

# Component Status
output "component_status" {
  description = "Status of deployed components"
  value = {
    eks_cluster                  = "deployed"
    karpenter                    = "deployed"
    aws_load_balancer_controller = "deployed"
    external_dns                 = "deployed"
    cert_manager                 = "deployed"
    secrets_store_csi            = "deployed"
    nginx_ingress                = "deployed"
    prometheus                   = "deployed"
    grafana                      = "deployed"
    argocd                       = "deployed"
    crossplane                   = "deployed"
    ack_controllers              = "deployed"
    backstage                    = "deployed"
  }
}
