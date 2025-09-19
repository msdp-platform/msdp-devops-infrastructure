# AWS Development Environment Variables

variable "environment" {
  description = "Environment name"
  type        = string
  default     = "dev"
}

variable "cluster_name" {
  description = "EKS cluster name"
  type        = string
  default     = "eks-msdp-dev-01"
}

variable "aws_region" {
  description = "AWS region"
  type        = string
  default     = "eu-west-1"
}

variable "domain_name" {
  description = "Domain name for DNS management"
  type        = string
  default     = "aztech-msdp.com" # Override with your organization's domain
}

variable "hosted_zone_id" {
  description = "Route53 hosted zone ID"
  type        = string
  default     = "Z0581458B5QGVNLDPESN" # Override with your Route53 zone ID
}

variable "cert_manager_email" {
  description = "Email address for Let's Encrypt certificates"
  type        = string
  default     = "devops@aztech-msdp.com" # Override with your organization's email
}

variable "ebs_kms_key_id" {
  description = "KMS key ID for EBS encryption"
  type        = string
  default     = "alias/aws/ebs"
}

# Plugin configuration
variable "plugins" {
  description = "Plugin enablement configuration"
  type = object({
    external_dns = object({
      enabled = bool
    })
    cert_manager = object({
      enabled = bool
    })
    nginx_ingress = object({
      enabled = bool
    })
    karpenter = object({
      enabled = bool
    })
    ebs_csi_driver = object({
      enabled = bool
    })
    efs_csi_driver = object({
      enabled = bool
    })
    aws_load_balancer_controller = object({
      enabled = bool
    })
    aws_node_termination_handler = object({
      enabled = bool
    })
    prometheus_stack = object({
      enabled = bool
    })
    grafana = object({
      enabled = bool
    })
    fluent_bit = object({
      enabled = bool
    })
    external_secrets = object({
      enabled = bool
    })
    argocd = object({
      enabled = bool
    })
    velero = object({
      enabled = bool
    })
  })
  
  default = {
    external_dns                 = { enabled = true }
    cert_manager                = { enabled = true }
    nginx_ingress               = { enabled = true }
    karpenter                   = { enabled = true }
    ebs_csi_driver             = { enabled = true }
    efs_csi_driver             = { enabled = false }
    aws_load_balancer_controller = { enabled = false }
    aws_node_termination_handler = { enabled = true }
    prometheus_stack            = { enabled = true }
    grafana                     = { enabled = true }
    fluent_bit                  = { enabled = true }
    external_secrets            = { enabled = true }
    argocd                      = { enabled = false }
    velero                      = { enabled = false }
  }
}