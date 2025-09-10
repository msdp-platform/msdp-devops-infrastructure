# Development Environment - EKS with Karpenter

terraform {
  required_version = ">= 1.0"
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
    helm = {
      source  = "hashicorp/helm"
      version = "~> 2.0"
    }
    kubectl = {
      source  = "gavinbunney/kubectl"
      version = "~> 1.14"
    }
  }

  backend "s3" {
    # Terraform state bucket created by OIDC setup
    bucket = "msdp-terraform-state-1757477736"
    key    = "dev/eks-blueprint/terraform.tfstate"
    region = "us-west-2"
  }
}

# Configure the AWS Provider
provider "aws" {
  region = var.aws_region

  default_tags {
    tags = {
      Environment = "dev"
      Project     = "msdp"
      ManagedBy   = "terraform"
    }
  }
}

# Configure the Helm Provider
provider "helm" {
  kubernetes {
    host                   = module.eks_blueprint.cluster_endpoint
    cluster_ca_certificate = base64decode(module.eks_blueprint.cluster_certificate_authority_data)

    exec {
      api_version = "client.authentication.k8s.io/v1beta1"
      command     = "aws"
      args        = ["eks", "get-token", "--cluster-name", module.eks_blueprint.cluster_name]
    }
  }
}

# Configure the Kubectl Provider
provider "kubectl" {
  host                   = module.eks_blueprint.cluster_endpoint
  cluster_ca_certificate = base64decode(module.eks_blueprint.cluster_certificate_authority_data)

  exec {
    api_version = "client.authentication.k8s.io/v1beta1"
    command     = "aws"
    args        = ["eks", "get-token", "--cluster-name", module.eks_blueprint.cluster_name]
  }
}

# EKS Blueprint Module
module "eks_blueprint" {
  source = "../../modules/eks-blueprint"

  cluster_name = var.cluster_name
  aws_region   = var.aws_region
  vpc_cidr     = var.vpc_cidr

  kubernetes_version = var.kubernetes_version
  karpenter_version  = var.karpenter_version

  karpenter_instance_types = var.karpenter_instance_types

  aws_auth_users = var.aws_auth_users

  domain_name            = var.domain_name
  create_route53_zone    = var.create_route53_zone
  route53_zone_id        = var.route53_zone_id
  create_acm_certificate = var.create_acm_certificate
  letsencrypt_email      = var.letsencrypt_email

  tags = {
    Environment = "dev"
    Project     = "msdp"
    ManagedBy   = "terraform"
    CostCenter  = "engineering"
  }
}

# All NodePools are now configured in the comprehensive module

