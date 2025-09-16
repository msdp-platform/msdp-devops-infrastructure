# Azure Development Environment - Kubernetes Add-ons
# This configuration deploys all enabled add-ons to Azure AKS dev cluster

terraform {
  required_version = ">= 1.9"
  
  required_providers {
    helm = {
      source  = "hashicorp/helm"
      version = "~> 2.12"
    }
    kubernetes = {
      source  = "hashicorp/kubernetes"
      version = "~> 2.24"
    }
    azurerm = {
      source  = "hashicorp/azurerm"
      version = "~> 3.0"
    }
  }
  
  backend "s3" {
    bucket = "msdp-terraform-state-dev"
    key    = "azure/addons/dev/uksouth/terraform.tfstate"
    region = "eu-west-1"
    
    dynamodb_table = "msdp-terraform-locks-dev"
    encrypt        = true
  }
}

# Configure providers
provider "azurerm" {
  features {}
  subscription_id = var.azure_subscription_id
  tenant_id       = var.azure_tenant_id
}

provider "kubernetes" {
  host                   = data.azurerm_kubernetes_cluster.cluster.kube_config.0.host
  client_certificate     = base64decode(data.azurerm_kubernetes_cluster.cluster.kube_config.0.client_certificate)
  client_key             = base64decode(data.azurerm_kubernetes_cluster.cluster.kube_config.0.client_key)
  cluster_ca_certificate = base64decode(data.azurerm_kubernetes_cluster.cluster.kube_config.0.cluster_ca_certificate)
}

provider "helm" {
  kubernetes {
    host                   = data.azurerm_kubernetes_cluster.cluster.kube_config.0.host
    client_certificate     = base64decode(data.azurerm_kubernetes_cluster.cluster.kube_config.0.client_certificate)
    client_key             = base64decode(data.azurerm_kubernetes_cluster.cluster.kube_config.0.client_key)
    cluster_ca_certificate = base64decode(data.azurerm_kubernetes_cluster.cluster.kube_config.0.cluster_ca_certificate)
  }
}

# Data sources
data "azurerm_kubernetes_cluster" "cluster" {
  name                = var.cluster_name
  resource_group_name = var.azure_resource_group
}

data "azurerm_client_config" "current" {}

# Local values
locals {
  subscription_id = data.azurerm_client_config.current.subscription_id
  
  # Common tags
  common_tags = {
    Environment   = var.environment
    CloudProvider = "azure"
    Cluster       = var.cluster_name
    ManagedBy     = "terraform"
  }
  
  # Plugin configurations
  plugins = {
    external_dns = {
      enabled = var.plugins.external_dns.enabled
      txt_owner_id = var.cluster_name
    }
    
    cert_manager = {
      enabled = var.plugins.cert_manager.enabled
      cluster_issuer = var.environment == "prod" ? "letsencrypt-prod" : "letsencrypt-staging"
    }
    
    nginx_ingress = {
      enabled = var.plugins.nginx_ingress.enabled
      replica_count = var.environment == "prod" ? 3 : 2
    }
    
    virtual_node = {
      enabled = var.plugins.virtual_node.enabled
    }
    
    azure_disk_csi_driver = {
      enabled = var.plugins.azure_disk_csi_driver.enabled
    }
    
    keda = {
      enabled = var.plugins.keda.enabled
    }
  }
}

# External DNS (using AWS Route53 for cross-cloud DNS with OIDC)
module "external_dns" {
  source = "../../modules/external-dns"
  
  enabled = local.plugins.external_dns.enabled
  
  # DNS configuration
  domain_filters = [var.domain_name]
  txt_owner_id   = local.plugins.external_dns.txt_owner_id
  hosted_zone_id = var.hosted_zone_id
  
  # Cloud configuration (Azure cluster using AWS Route53 with OIDC)
  cloud_provider              = "azure"
  aws_region                 = var.aws_region
  aws_role_arn               = var.aws_role_arn_for_azure
  aws_web_identity_token_file = var.aws_web_identity_token_file
  use_oidc                   = true
  
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

# Cert-Manager (using AWS Route53 for DNS challenges with OIDC)
module "cert_manager" {
  source = "../../modules/cert-manager"
  
  enabled = local.plugins.cert_manager.enabled
  
  # Certificate configuration
  email          = var.cert_manager_email
  cluster_issuer = local.plugins.cert_manager.cluster_issuer
  
  # DNS challenge configuration (using AWS Route53 with OIDC)
  dns_challenge           = true
  dns_provider            = "route53"
  hosted_zone_id          = var.hosted_zone_id
  aws_region             = var.aws_region
  aws_role_arn           = var.aws_role_arn_for_azure
  aws_web_identity_token_file = var.aws_web_identity_token_file
  
  # Cloud configuration
  cloud_provider = "azure"
  
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
  
  # Azure-specific annotations
  service_annotations = {
    "service.beta.kubernetes.io/azure-load-balancer-health-probe-request-path" = "/healthz"
    "service.beta.kubernetes.io/azure-load-balancer-health-probe-port"         = "10254"
    "service.beta.kubernetes.io/azure-load-balancer-health-probe-protocol"     = "http"
  }
  
  # SSL configuration
  enable_ssl_redirect = true
  
  # Dependencies
  depends_on = [module.cert_manager]
}

# Virtual Node (Azure-specific)
module "virtual_node" {
  source = "../../modules/virtual-node"
  
  enabled = local.plugins.virtual_node.enabled
  
  # Azure configuration
  resource_group_name = var.azure_resource_group
  subnet_name        = var.virtual_node_subnet_name
  
  # Node configuration
  node_labels = {
    "kubernetes.azure.com/mode" = "virtual"
    "type"                      = "virtual-kubelet"
  }
  
  node_taints = [
    {
      key    = "virtual-kubelet.io/provider"
      value  = "azure"
      effect = "NoSchedule"
    }
  ]
}

# Azure Disk CSI Driver (Azure-specific)
module "azure_disk_csi_driver" {
  source = "../../modules/azure-disk-csi-driver"
  
  enabled = local.plugins.azure_disk_csi_driver.enabled
  
  # Storage classes
  create_storage_classes = true
  default_storage_class  = "managed-premium"
  
  # Encryption
  enable_encryption = true
}

# KEDA (Azure-specific)
module "keda" {
  source = "../../modules/keda"
  
  enabled = local.plugins.keda.enabled
  
  # Azure integration
  azure_subscription_id = local.subscription_id
  azure_resource_group  = var.azure_resource_group
  
  # Scaling configuration
  log_level = var.environment == "prod" ? "info" : "debug"
  
  # Resource configuration
  resources = {
    requests = {
      cpu    = "100m"
      memory = "128Mi"
    }
    limits = {
      cpu    = var.environment == "prod" ? "1000m" : "500m"
      memory = var.environment == "prod" ? "1Gi" : "512Mi"
    }
  }
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

output "virtual_node_status" {
  description = "Virtual Node deployment status"
  value = {
    enabled   = module.virtual_node.namespace != null
    namespace = module.virtual_node.namespace
    version   = module.virtual_node.helm_release_version
  }
}

output "azure_disk_csi_status" {
  description = "Azure Disk CSI Driver deployment status"
  value = {
    enabled   = module.azure_disk_csi_driver.namespace != null
    namespace = module.azure_disk_csi_driver.namespace
    version   = module.azure_disk_csi_driver.helm_release_version
  }
}

output "keda_status" {
  description = "KEDA deployment status"
  value = {
    enabled   = module.keda.namespace != null
    namespace = module.keda.namespace
    version   = module.keda.helm_release_version
  }
}

output "addons_summary" {
  description = "Summary of all deployed add-ons"
  value = {
    environment    = var.environment
    cloud_provider = "azure"
    cluster_name   = var.cluster_name
    domain_name    = var.domain_name
    
    deployed_addons = [
      for addon in [
        { name = "external-dns", enabled = local.plugins.external_dns.enabled },
        { name = "cert-manager", enabled = local.plugins.cert_manager.enabled },
        { name = "nginx-ingress", enabled = local.plugins.nginx_ingress.enabled },
        { name = "virtual-node", enabled = local.plugins.virtual_node.enabled },
        { name = "azure-disk-csi-driver", enabled = local.plugins.azure_disk_csi_driver.enabled },
        { name = "keda", enabled = local.plugins.keda.enabled },
      ] : addon.name if addon.enabled
    ]
    
    dependencies = {
      "external-dns" = "foundation"
      "cert-manager" = "depends on external-dns"
      "nginx-ingress" = "depends on cert-manager"
      "virtual-node" = "independent"
      "azure-disk-csi-driver" = "independent"
      "keda" = "independent"
    }
  }
}