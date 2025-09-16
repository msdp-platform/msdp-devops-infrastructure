# AWS Development Environment - Kubernetes Add-ons
# This configuration deploys all enabled add-ons to AWS EKS dev cluster

terraform {
  required_version = ">= 1.6"
  
  required_providers {
    helm = {
      source  = "hashicorp/helm"
      version = "~> 2.12"
    }
    kubernetes = {
      source  = "hashicorp/kubernetes"
      version = "~> 2.24"
    }
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }
  
  backend "s3" {
    bucket = "msdp-terraform-state"
    key    = "addons/aws-dev/terraform.tfstate"
    region = "eu-west-1"
    
    dynamodb_table = "msdp-terraform-locks"
    encrypt        = true
  }
}

# Configure providers
provider "aws" {
  region = var.aws_region
  
  default_tags {
    tags = {
      Environment   = var.environment
      Project       = "msdp"
      ManagedBy     = "terraform"
      Component     = "kubernetes-addons"
    }
  }
}

provider "kubernetes" {
  host                   = data.aws_eks_cluster.cluster.endpoint
  cluster_ca_certificate = base64decode(data.aws_eks_cluster.cluster.certificate_authority[0].data)
  token                  = data.aws_eks_cluster_auth.cluster.token
}

provider "helm" {
  kubernetes {
    host                   = data.aws_eks_cluster.cluster.endpoint
    cluster_ca_certificate = base64decode(data.aws_eks_cluster.cluster.certificate_authority[0].data)
    token                  = data.aws_eks_cluster_auth.cluster.token
  }
}

# Data sources
data "aws_eks_cluster" "cluster" {
  name = var.cluster_name
}

data "aws_eks_cluster_auth" "cluster" {
  name = var.cluster_name
}

data "aws_caller_identity" "current" {}

# Local values
locals {
  account_id = data.aws_caller_identity.current.account_id
  
  # Common tags
  common_tags = {
    Environment = var.environment
    CloudProvider = "aws"
    Cluster = var.cluster_name
  }
  
  # Plugin configurations
  plugins = {
    external_dns = {
      enabled = var.plugins.external_dns.enabled
      txt_owner_id = var.cluster_name
      aws_role_arn = "arn:aws:iam::${local.account_id}:role/ExternalDNSRole"
    }
    
    cert_manager = {
      enabled = var.plugins.cert_manager.enabled
      cluster_issuer = var.environment == "prod" ? "letsencrypt-prod" : "letsencrypt-staging"
      aws_role_arn = "arn:aws:iam::${local.account_id}:role/CertManagerRole"
    }
    
    nginx_ingress = {
      enabled = var.plugins.nginx_ingress.enabled
      replica_count = var.environment == "prod" ? 3 : 2
    }
    
    karpenter = {
      enabled = var.plugins.karpenter.enabled
      cluster_name = var.cluster_name
      aws_role_arn = "arn:aws:iam::${local.account_id}:role/KarpenterRole"
    }
    
    ebs_csi_driver = {
      enabled = var.plugins.ebs_csi_driver.enabled
      aws_role_arn = "arn:aws:iam::${local.account_id}:role/EBSCSIDriverRole"
    }
  }
}

# External DNS
module "external_dns" {
  source = "../../modules/external-dns"
  
  enabled = local.plugins.external_dns.enabled
  
  # DNS configuration
  domain_filters = [var.domain_name]
  txt_owner_id   = local.plugins.external_dns.txt_owner_id
  hosted_zone_id = var.hosted_zone_id
  
  # Cloud configuration
  cloud_provider = "aws"
  aws_region     = var.aws_region
  aws_role_arn   = local.plugins.external_dns.aws_role_arn
  
  # Application configuration
  replica_count = var.environment == "prod" ? 2 : 1
  log_level     = var.environment == "prod" ? "info" : "debug"
  
  # Resource configuration
  resources = {
    requests = {
      cpu    = "100m"
      memory = "128Mi"
    }
    limits = {
      cpu    = var.environment == "prod" ? "500m" : "200m"
      memory = var.environment == "prod" ? "512Mi" : "256Mi"
    }
  }
}

# Cert-Manager
module "cert_manager" {
  source = "../../modules/cert-manager"
  
  enabled = local.plugins.cert_manager.enabled
  
  # Certificate configuration
  email          = var.cert_manager_email
  cluster_issuer = local.plugins.cert_manager.cluster_issuer
  
  # DNS challenge configuration
  dns_challenge  = true
  dns_provider   = "route53"
  hosted_zone_id = var.hosted_zone_id
  
  # Cloud configuration
  cloud_provider = "aws"
  aws_region     = var.aws_region
  aws_role_arn   = local.plugins.cert_manager.aws_role_arn
  
  # Dependencies
  depends_on = [module.external_dns]
}

# NGINX Ingress Controller
module "nginx_ingress" {
  source = "../../modules/nginx-ingress"
  
  enabled = local.plugins.nginx_ingress.enabled
  
  # Configuration
  replica_count = local.plugins.nginx_ingress.replica_count
  service_type  = "LoadBalancer"
  
  # AWS-specific annotations
  service_annotations = {
    "service.beta.kubernetes.io/aws-load-balancer-type"                              = "nlb"
    "service.beta.kubernetes.io/aws-load-balancer-cross-zone-load-balancing-enabled" = "true"
    "service.beta.kubernetes.io/aws-load-balancer-backend-protocol"                  = "tcp"
  }
  
  # SSL configuration
  enable_ssl_redirect = true
  
  # Dependencies
  depends_on = [module.cert_manager]
}

# Karpenter (AWS-specific)
module "karpenter" {
  source = "../../modules/karpenter"
  
  enabled = local.plugins.karpenter.enabled
  
  # Cluster configuration
  cluster_name = local.plugins.karpenter.cluster_name
  
  # IAM configuration
  aws_role_arn = local.plugins.karpenter.aws_role_arn
  
  # Node configuration
  instance_types = var.environment == "prod" ? 
    ["m5.large", "m5.xlarge", "m5.2xlarge", "c5.large", "c5.xlarge"] :
    ["t3.medium", "t3.large", "m5.large"]
  
  # Spot instance configuration
  spot_enabled = var.environment != "prod"
  
  # Taints and labels
  node_taints = var.environment == "prod" ? [] : [
    {
      key    = "node.kubernetes.io/instance-type"
      value  = "spot"
      effect = "NoSchedule"
    }
  ]
}

# EBS CSI Driver (AWS-specific)
module "ebs_csi_driver" {
  source = "../../modules/ebs-csi-driver"
  
  enabled = local.plugins.ebs_csi_driver.enabled
  
  # IAM configuration
  aws_role_arn = local.plugins.ebs_csi_driver.aws_role_arn
  
  # Storage classes
  create_storage_classes = true
  default_storage_class  = "gp3"
  
  # Encryption
  enable_encryption = true
  kms_key_id       = var.ebs_kms_key_id
}

# Outputs
output "external_dns_status" {
  description = "External DNS deployment status"
  value = {
    enabled   = module.external_dns.namespace != null
    namespace = module.external_dns.namespace
    version   = module.external_dns.helm_release_version
  }
}

output "cert_manager_status" {
  description = "Cert-Manager deployment status"
  value = {
    enabled   = module.cert_manager.namespace != null
    namespace = module.cert_manager.namespace
    version   = module.cert_manager.helm_release_version
  }
}

output "nginx_ingress_status" {
  description = "NGINX Ingress Controller deployment status"
  value = {
    enabled   = module.nginx_ingress.namespace != null
    namespace = module.nginx_ingress.namespace
    version   = module.nginx_ingress.helm_release_version
  }
}

output "karpenter_status" {
  description = "Karpenter deployment status"
  value = {
    enabled   = module.karpenter.namespace != null
    namespace = module.karpenter.namespace
    version   = module.karpenter.helm_release_version
  }
}

output "addons_summary" {
  description = "Summary of all deployed add-ons"
  value = {
    environment    = var.environment
    cloud_provider = "aws"
    cluster_name   = var.cluster_name
    domain_name    = var.domain_name
    
    deployed_addons = [
      for addon in [
        { name = "external-dns", enabled = local.plugins.external_dns.enabled },
        { name = "cert-manager", enabled = local.plugins.cert_manager.enabled },
        { name = "nginx-ingress", enabled = local.plugins.nginx_ingress.enabled },
        { name = "karpenter", enabled = local.plugins.karpenter.enabled },
        { name = "ebs-csi-driver", enabled = local.plugins.ebs_csi_driver.enabled },
      ] : addon.name if addon.enabled
    ]
  }
}