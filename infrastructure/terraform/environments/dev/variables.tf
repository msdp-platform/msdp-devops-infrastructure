# Variables for Development Environment

variable "cluster_name" {
  description = "Name of the EKS cluster"
  type        = string
  default     = "msdp-eks-dev"
}

variable "aws_region" {
  description = "AWS region"
  type        = string
  default     = "us-west-2"
}

variable "vpc_cidr" {
  description = "CIDR block for VPC"
  type        = string
  default     = "10.0.0.0/16"
}

variable "kubernetes_version" {
  description = "Kubernetes version"
  type        = string
  default     = "1.28"
}

variable "karpenter_version" {
  description = "Karpenter version"
  type        = string
  default     = "0.37.0"
}

variable "karpenter_instance_types" {
  description = "Instance types for Karpenter nodes - ARM-based for cost optimization"
  type        = list(string)
  default = [
    # ARM-based instances (Graviton) - up to 40% better price/performance
    "t4g.medium",
    "t4g.large",
    "t4g.xlarge",
    "t4g.2xlarge",
    "m6g.medium",
    "m6g.large",
    "m6g.xlarge",
    "m6g.2xlarge",
    "m6g.4xlarge",
    "c6g.medium",
    "c6g.large",
    "c6g.xlarge",
    "c6g.2xlarge",
    "c6g.4xlarge",
    "r6g.medium",
    "r6g.large",
    "r6g.xlarge",
    "r6g.2xlarge",
    "r6g.4xlarge"
  ]
}

variable "aws_auth_users" {
  description = "List of AWS users to add to aws-auth configmap"
  type = list(object({
    userarn  = string
    username = string
    groups   = list(string)
  }))
  default = []
}

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

