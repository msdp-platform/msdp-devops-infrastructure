# Variables for Comprehensive EKS Blueprint

variable "cluster_name" {
  description = "Name of the EKS cluster"
  type        = string
  default     = "msdp-eks"
}

variable "aws_region" {
  description = "AWS region"
  type        = string
  default     = "us-west-2"
}

variable "kubernetes_version" {
  description = "Kubernetes version"
  type        = string
  default     = "1.28"
}

variable "vpc_cidr" {
  description = "CIDR block for VPC"
  type        = string
  default     = "10.0.0.0/16"
}

# Component Versions
variable "karpenter_version" {
  description = "Karpenter version"
  type        = string
  default     = "0.37.0"
}

variable "aws_load_balancer_controller_version" {
  description = "AWS Load Balancer Controller version"
  type        = string
  default     = "1.6.2"
}

variable "external_dns_version" {
  description = "External DNS version"
  type        = string
  default     = "1.13.1"
}

variable "cert_manager_version" {
  description = "Cert-Manager version"
  type        = string
  default     = "v1.13.2"
}

variable "secrets_store_csi_version" {
  description = "Secrets Store CSI Driver version"
  type        = string
  default     = "1.3.4"
}

variable "secrets_store_csi_aws_provider_version" {
  description = "Secrets Store CSI AWS Provider version"
  type        = string
  default     = "0.3.4"
}

variable "nginx_ingress_version" {
  description = "NGINX Ingress Controller version"
  type        = string
  default     = "4.8.3"
}

variable "prometheus_version" {
  description = "Prometheus version"
  type        = string
  default     = "55.4.0"
}

variable "argocd_version" {
  description = "ArgoCD version"
  type        = string
  default     = "5.51.6"
}

variable "crossplane_version" {
  description = "Crossplane version"
  type        = string
  default     = "1.14.1"
}

variable "ack_s3_version" {
  description = "ACK S3 Controller version"
  type        = string
  default     = "1.0.0"
}

variable "ack_rds_version" {
  description = "ACK RDS Controller version"
  type        = string
  default     = "1.0.0"
}

variable "backstage_version" {
  description = "Backstage version"
  type        = string
  default     = "0.1.0"
}

# Instance Types - Cost-optimized mixed architecture (ARM + x86)
variable "karpenter_instance_types" {
  description = "Instance types for Karpenter nodes - Cost-optimized mixed architecture (ARM + x86)"
  type        = list(string)
  default = [
    # ARM-based instances (Graviton) - Up to 40% better price/performance
    # t4g instances - General purpose with good memory
    "t4g.medium", "t4g.large", "t4g.xlarge", "t4g.2xlarge", "t4g.4xlarge",
    # r6g instances - Memory-optimized (high memory to CPU ratio)
    "r6g.medium", "r6g.large", "r6g.xlarge", "r6g.2xlarge", "r6g.4xlarge", 
    "r6g.8xlarge", "r6g.12xlarge", "r6g.16xlarge",
    # m6g instances - Balanced memory and compute
    "m6g.medium", "m6g.large", "m6g.xlarge", "m6g.2xlarge", "m6g.4xlarge",
    "m6g.8xlarge", "m6g.12xlarge", "m6g.16xlarge",
    # c6g instances - Compute-optimized
    "c6g.medium", "c6g.large", "c6g.xlarge", "c6g.2xlarge", "c6g.4xlarge",
    
    # x86-based instances - For cost comparison and availability
    # t3 instances - General purpose (often cheaper than t4g in some regions)
    "t3.medium", "t3.large", "t3.xlarge", "t3.2xlarge",
    # t3a instances - AMD-based, often cheapest
    "t3a.medium", "t3a.large", "t3a.xlarge", "t3a.2xlarge",
    # m5 instances - General purpose
    "m5.medium", "m5.large", "m5.xlarge", "m5.2xlarge", "m5.4xlarge",
    # m5a instances - AMD-based, often cheaper
    "m5a.medium", "m5a.large", "m5a.xlarge", "m5a.2xlarge", "m5a.4xlarge",
    # r5 instances - Memory-optimized
    "r5.medium", "r5.large", "r5.xlarge", "r5.2xlarge", "r5.4xlarge",
    # r5a instances - AMD-based memory-optimized
    "r5a.medium", "r5a.large", "r5a.xlarge", "r5a.2xlarge", "r5a.4xlarge",
    # c5 instances - Compute-optimized
    "c5.medium", "c5.large", "c5.xlarge", "c5.2xlarge", "c5.4xlarge",
    # c5a instances - AMD-based compute-optimized
    "c5a.medium", "c5a.large", "c5a.xlarge", "c5a.2xlarge", "c5a.4xlarge"
  ]
}

# DNS and Certificate Configuration
variable "domain_name" {
  description = "Domain name for the cluster"
  type        = string
  default     = "example.com"
}

variable "create_route53_zone" {
  description = "Whether to create a Route53 hosted zone"
  type        = bool
  default     = false
}

variable "route53_zone_id" {
  description = "Route53 hosted zone ID (if not creating one)"
  type        = string
  default     = ""
}

variable "create_acm_certificate" {
  description = "Whether to create an ACM certificate"
  type        = bool
  default     = false
}

variable "letsencrypt_email" {
  description = "Email for Let's Encrypt certificate registration"
  type        = string
  default     = "admin@example.com"
}

# AWS Auth
variable "aws_auth_users" {
  description = "List of AWS users to add to aws-auth configmap"
  type = list(object({
    userarn  = string
    username = string
    groups   = list(string)
  }))
  default = []
}

# Tags
variable "tags" {
  description = "A map of tags to assign to the resource"
  type        = map(string)
  default = {
    Environment = "dev"
    Project     = "msdp"
    ManagedBy   = "terraform"
  }
}
