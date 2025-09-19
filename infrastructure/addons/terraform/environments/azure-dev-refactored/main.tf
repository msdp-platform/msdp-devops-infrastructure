# Refactored Azure Dev Environment Configuration
# This configuration demonstrates DRY principles and improved organization

terraform {
  required_version = ">= 1.5"

  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = "~> 3.80"
    }
    kubernetes = {
      source  = "hashicorp/kubernetes"
      version = "~> 2.24"
    }
    helm = {
      source  = "hashicorp/helm"
      version = "~> 2.15"
    }
  }
}

# Use shared version management
module "versions" {
  source = "../../modules/shared/versions"
}

# Local configuration with improved organization
locals {
  # Environment-specific settings
  environment_config = {
    name         = var.environment
    cluster_name = var.cluster_name
    domain_name  = var.domain_name
    is_prod      = var.environment == "prod"
  }

  # AWS configuration for cross-cloud access
  aws_config = {
    region             = var.aws_region
    hosted_zone_id     = var.hosted_zone_id
    access_key_id      = var.aws_access_key_id
    secret_access_key  = var.aws_secret_access_key
    role_arn           = var.aws_role_arn_for_azure
    web_identity_token = var.aws_web_identity_token_file
  }

  # Plugin configurations with consistent structure
  plugins = {
    external_dns = {
      enabled       = var.plugins.external_dns.enabled
      txt_owner_id  = local.environment_config.cluster_name
      replica_count = local.environment_config.is_prod ? 2 : 1
    }

    cert_manager = {
      enabled        = var.plugins.cert_manager.enabled
      cluster_issuer = "letsencrypt-prod"
      email          = var.cert_manager_email
    }

    nginx_ingress = {
      enabled       = var.plugins.nginx_ingress.enabled
      replica_count = local.environment_config.is_prod ? 3 : 2
    }

    prometheus_stack = {
      enabled = var.plugins.prometheus_stack.enabled
      grafana = {
        admin_password = var.grafana_admin_password
        domain         = "grafana.${local.environment_config.domain_name}"
      }
      prometheus = {
        domain = "prometheus.${local.environment_config.domain_name}"
      }
    }

    argocd = {
      enabled = var.plugins.argocd.enabled
      domain  = "argocd.${local.environment_config.domain_name}"
    }

    virtual_node = {
      enabled = var.plugins.virtual_node.enabled
    }

    crossplane = {
      enabled = var.plugins.crossplane.enabled
    }

    backstage = {
      enabled = var.plugins.backstage.enabled
    }
  }

  # Resource configurations based on environment
  resource_configs = {
    small = {
      requests = { cpu = "100m", memory = "128Mi" }
      limits   = { cpu = "200m", memory = "256Mi" }
    }
    medium = {
      requests = { cpu = "200m", memory = "256Mi" }
      limits   = { cpu = "500m", memory = "512Mi" }
    }
    large = {
      requests = { cpu = "500m", memory = "512Mi" }
      limits   = { cpu = "1000m", memory = "1Gi" }
    }
  }
}

# External DNS with shared components
module "external_dns" {
  source = "../../modules/external-dns"

  enabled = local.plugins.external_dns.enabled

  # DNS configuration
  domain_filters = [local.environment_config.domain_name]
  txt_owner_id   = local.plugins.external_dns.txt_owner_id
  hosted_zone_id = local.aws_config.hosted_zone_id

  # Cloud configuration
  cloud_provider        = "azure"
  aws_region            = local.aws_config.region
  aws_access_key_id     = local.aws_config.access_key_id
  aws_secret_access_key = local.aws_config.secret_access_key
  use_oidc              = false

  # Application configuration
  replica_count = local.plugins.external_dns.replica_count
  log_level     = local.environment_config.is_prod ? "info" : "debug"
  chart_version = module.versions.chart_versions.external_dns

  # Resource configuration
  resources = local.environment_config.is_prod ? local.resource_configs.medium : local.resource_configs.small
}

# Cert-Manager with shared components
module "cert_manager" {
  source = "../../modules/cert-manager"

  enabled = local.plugins.cert_manager.enabled

  # Certificate configuration
  email                 = local.plugins.cert_manager.email
  cluster_issuer_name   = local.plugins.cert_manager.cluster_issuer
  create_cluster_issuer = false # We'll create explicitly below
  chart_version         = module.versions.chart_versions.cert_manager

  # DNS challenge configuration
  dns_challenge         = true
  dns_provider          = "route53"
  hosted_zone_id        = local.aws_config.hosted_zone_id
  aws_region            = local.aws_config.region
  aws_access_key_id     = local.aws_config.access_key_id
  aws_secret_access_key = local.aws_config.secret_access_key
  use_oidc              = false

  # Cloud configuration
  cloud_provider = "azure"

  # Resource configuration
  resources = local.environment_config.is_prod ? local.resource_configs.medium : local.resource_configs.small

  # Dependencies
  depends_on = [module.external_dns]
}

# Explicit ClusterIssuer creation with proper AWS credentials
resource "kubernetes_manifest" "cluster_issuer" {
  count = local.plugins.cert_manager.enabled ? 1 : 0

  manifest = {
    apiVersion = "cert-manager.io/v1"
    kind       = "ClusterIssuer"
    metadata = {
      name = local.plugins.cert_manager.cluster_issuer
      labels = {
        "app.kubernetes.io/name"       = "cert-manager"
        "app.kubernetes.io/managed-by" = "terraform"
      }
    }
    spec = {
      acme = {
        server = "https://acme-v02.api.letsencrypt.org/directory"
        email  = local.plugins.cert_manager.email
        privateKeySecretRef = {
          name = "${local.plugins.cert_manager.cluster_issuer}-private-key"
        }
        solvers = [
          {
            dns01 = {
              route53 = {
                region       = local.aws_config.region
                hostedZoneID = local.aws_config.hosted_zone_id
                accessKeyIDSecretRef = {
                  name = "aws-credentials"
                  key  = "aws-access-key-id"
                }
                secretAccessKeySecretRef = {
                  name = "aws-credentials"
                  key  = "aws-secret-access-key"
                }
              }
            }
          }
        ]
      }
    }
  }

  depends_on = [
    module.cert_manager,
    module.external_dns
  ]
}

# NGINX Ingress Controller
module "nginx_ingress" {
  source = "../../modules/nginx-ingress"
  count  = local.plugins.nginx_ingress.enabled ? 1 : 0

  replica_count = local.plugins.nginx_ingress.replica_count
  chart_version = module.versions.chart_versions.nginx_ingress

  # Resource configuration
  resources = local.environment_config.is_prod ? local.resource_configs.large : local.resource_configs.medium
}

# Prometheus Stack
module "prometheus_stack" {
  source = "../../modules/prometheus-stack"
  count  = local.plugins.prometheus_stack.enabled ? 1 : 0

  # Hostname configuration
  prometheus_hostname = local.plugins.prometheus_stack.prometheus.domain
  grafana_hostname    = local.plugins.prometheus_stack.grafana.domain

  # Ingress configuration
  cluster_issuer_name = "letsencrypt-prod"
  ingress_class_name  = "nginx"

  # TLS configuration
  prometheus_tls_secret_name = "prometheus-tls"
  grafana_tls_secret_name    = "grafana-tls"

  depends_on = [module.nginx_ingress]
}

# ArgoCD
module "argocd" {
  source = "../../modules/argocd"
  count  = local.plugins.argocd.enabled ? 1 : 0

  chart_version = module.versions.chart_versions.argocd
  domain        = local.plugins.argocd.domain

  # Resource configuration
  resources = local.environment_config.is_prod ? local.resource_configs.medium : local.resource_configs.small

  depends_on = [module.nginx_ingress]
}

# Virtual Node (Azure Container Instances)
module "virtual_node" {
  source = "../../modules/virtual-node"
  count  = local.plugins.virtual_node.enabled ? 1 : 0

  depends_on = [module.nginx_ingress]
}

# Crossplane
module "crossplane" {
  source = "../../modules/crossplane"
  count  = local.plugins.crossplane.enabled ? 1 : 0

  chart_version = module.versions.chart_versions.crossplane

  # AWS provider configuration
  crossplane_providers = {
    aws = {
      enabled = true
    }
  }

  aws_access_key_id     = local.aws_config.access_key_id
  aws_secret_access_key = local.aws_config.secret_access_key
  aws_region            = local.aws_config.region
}

# Backstage
module "backstage" {
  source = "../../modules/backstage"
  count  = local.plugins.backstage.enabled ? 1 : 0

  chart_version = module.versions.chart_versions.backstage

  depends_on = [module.nginx_ingress]
}

# Outputs with improved organization
output "addon_status" {
  description = "Status of all deployed addons"
  value = {
    environment = local.environment_config.name
    cluster     = local.environment_config.cluster_name

    deployed_addons = [
      for addon in [
        { name = "external-dns", enabled = local.plugins.external_dns.enabled },
        { name = "cert-manager", enabled = local.plugins.cert_manager.enabled },
        { name = "nginx-ingress", enabled = local.plugins.nginx_ingress.enabled },
        { name = "prometheus-stack", enabled = local.plugins.prometheus_stack.enabled },
        { name = "argocd", enabled = local.plugins.argocd.enabled },
        { name = "virtual-node", enabled = local.plugins.virtual_node.enabled },
        { name = "crossplane", enabled = local.plugins.crossplane.enabled },
        { name = "backstage", enabled = local.plugins.backstage.enabled },
      ] : addon.name if addon.enabled
    ]

    endpoints = {
      grafana    = local.plugins.prometheus_stack.enabled ? "https://${local.plugins.prometheus_stack.grafana.domain}" : null
      prometheus = local.plugins.prometheus_stack.enabled ? "https://${local.plugins.prometheus_stack.prometheus.domain}" : null
      argocd     = local.plugins.argocd.enabled ? "https://${local.plugins.argocd.domain}" : null
    }
  }
}
