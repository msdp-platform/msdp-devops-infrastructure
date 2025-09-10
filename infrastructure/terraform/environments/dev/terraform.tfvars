# Terraform variables for dev environment

# Cluster Configuration
cluster_name = "msdp-eks-dev"
aws_region   = "us-west-2"
vpc_cidr     = "10.0.0.0/16"

# Kubernetes Configuration
kubernetes_version = "1.28"
karpenter_version  = "0.37.0"

# Component Versions (compatible with Kubernetes 1.28)
aws_load_balancer_controller_version   = "1.6.2"
external_dns_version                   = "1.13.1"
cert_manager_version                   = "v1.13.2"
secrets_store_csi_version              = "1.3.4"
secrets_store_csi_aws_provider_version = "0.3.4"
nginx_ingress_version                  = "4.8.3"
prometheus_version                     = "55.4.0"
argocd_version                         = "5.51.6"
crossplane_version                     = "1.14.1"
ack_s3_version                         = "1.1.0"
ack_rds_version                        = "1.1.0"
backstage_version                      = "0.1.0"

# Instance Types for Karpenter - Cost-optimized mixed architecture (ARM + x86)
karpenter_instance_types = [
  # ARM-based instances (Graviton) - Up to 40% better price/performance
  "t4g.medium", "t4g.large", "t4g.xlarge", "t4g.2xlarge", "t4g.4xlarge",
  "r6g.medium", "r6g.large", "r6g.xlarge", "r6g.2xlarge", "r6g.4xlarge",
  "m6g.medium", "m6g.large", "m6g.xlarge", "m6g.2xlarge", "m6g.4xlarge",
  "c6g.medium", "c6g.large", "c6g.xlarge", "c6g.2xlarge", "c6g.4xlarge",

  # x86-based instances - For cost comparison and availability
  "t3.medium", "t3.large", "t3.xlarge", "t3.2xlarge",
  "t3a.medium", "t3a.large", "t3a.xlarge", "t3a.2xlarge",
  "m5.medium", "m5.large", "m5.xlarge", "m5.2xlarge", "m5.4xlarge",
  "m5a.medium", "m5a.large", "m5a.xlarge", "m5a.2xlarge", "m5a.4xlarge",
  "r5.medium", "r5.large", "r5.xlarge", "r5.2xlarge", "r5.4xlarge",
  "r5a.medium", "r5a.large", "r5a.xlarge", "r5a.2xlarge", "r5a.4xlarge",
  "c5.medium", "c5.large", "c5.xlarge", "c5.2xlarge", "c5.4xlarge",
  "c5a.medium", "c5a.large", "c5a.xlarge", "c5a.2xlarge", "c5a.4xlarge"
]

# DNS and Certificate Configuration
domain_name            = "aztech-msdp.com"
create_route53_zone    = false
route53_zone_id        = "Z1234567890ABC"
create_acm_certificate = false
letsencrypt_email      = "admin@aztech-msdp.com"
