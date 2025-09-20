# Backstage Latest Version Terraform Module for MSDP

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
  }
}

# Provider configurations - explicitly use kubeconfig
provider "kubernetes" {
  config_path = var.kubeconfig_path
}

provider "helm" {
  kubernetes {
    config_path = var.kubeconfig_path
  }
}

# Load configuration
locals {
  component_config = var.component_config
  namespace        = var.namespace
  chart_version    = var.component_config.chart_version

  # MSDP-specific labels following your conventions
  common_labels = {
    "app.kubernetes.io/name"       = "backstage"
    "app.kubernetes.io/instance"   = "msdp-backstage"
    "app.kubernetes.io/version"    = local.chart_version
    "app.kubernetes.io/component"  = "developer-portal"
    "app.kubernetes.io/part-of"    = "msdp-platform-engineering"
    "app.kubernetes.io/managed-by" = "terraform"
    "msdp.platform/component"      = "backstage"
    "msdp.platform/environment"    = var.environment
  }

  # App configuration with MSDP-specific settings
  app_config = var.component_config.app_config

  # Database configuration
  postgresql_config = var.component_config.postgresql

  # Ingress configuration
  ingress_config = var.component_config.ingress
}

# Backstage namespace
resource "kubernetes_namespace" "backstage" {
  metadata {
    name   = local.namespace
    labels = local.common_labels
  }
}

# Backstage app configuration
resource "kubernetes_config_map" "backstage_config" {
  metadata {
    name      = "backstage-app-config"
    namespace = kubernetes_namespace.backstage.metadata[0].name
    labels    = local.common_labels
  }

  data = {
    "app-config.yaml" = yamlencode(local.app_config)
  }
}

# GitHub secrets for Backstage
resource "kubernetes_secret" "github_credentials" {
  metadata {
    name      = "github-credentials"
    namespace = kubernetes_namespace.backstage.metadata[0].name
    labels    = local.common_labels
  }

  data = {
    GITHUB_CLIENT_ID     = var.github_client_id
    GITHUB_CLIENT_SECRET = var.github_client_secret
    GITHUB_TOKEN         = var.github_token
  }

  type = "Opaque"
}

# PostgreSQL credentials
resource "kubernetes_secret" "postgres_credentials" {
  metadata {
    name      = "postgres-credentials"
    namespace = kubernetes_namespace.backstage.metadata[0].name
    labels    = local.common_labels
  }

  data = {
    POSTGRES_HOST     = local.postgresql_config.enabled ? "backstage-postgresql" : var.external_postgres_host
    POSTGRES_PORT     = "5432"
    POSTGRES_USER     = local.postgresql_config.auth.username
    POSTGRES_PASSWORD = local.postgresql_config.auth.password
    POSTGRES_DB       = local.postgresql_config.auth.database
  }

  type = "Opaque"
}

# Backstage Helm release (latest version)
resource "helm_release" "backstage" {
  name       = "backstage"
  repository = local.component_config.repository
  chart      = "backstage"
  version    = local.chart_version
  namespace  = kubernetes_namespace.backstage.metadata[0].name

  # Backstage values following MSDP requirements
  values = [
    yamlencode({
      # Backstage configuration
      backstage = {
        image = {
          repository = "backstage/backstage"
          tag        = var.component_config.app_version
        }

        # App configuration via ConfigMap
        appConfig = {
          configMapRef = kubernetes_config_map.backstage_config.metadata[0].name
        }

        # Environment variables from secrets
        extraEnvVars = [
          {
            name = "GITHUB_CLIENT_ID"
            valueFrom = {
              secretKeyRef = {
                name = kubernetes_secret.github_credentials.metadata[0].name
                key  = "GITHUB_CLIENT_ID"
              }
            }
          },
          {
            name = "GITHUB_CLIENT_SECRET"
            valueFrom = {
              secretKeyRef = {
                name = kubernetes_secret.github_credentials.metadata[0].name
                key  = "GITHUB_CLIENT_SECRET"
              }
            }
          },
          {
            name = "GITHUB_TOKEN"
            valueFrom = {
              secretKeyRef = {
                name = kubernetes_secret.github_credentials.metadata[0].name
                key  = "GITHUB_TOKEN"
              }
            }
          },
          {
            name = "POSTGRES_HOST"
            valueFrom = {
              secretKeyRef = {
                name = kubernetes_secret.postgres_credentials.metadata[0].name
                key  = "POSTGRES_HOST"
              }
            }
          },
          {
            name = "POSTGRES_PASSWORD"
            valueFrom = {
              secretKeyRef = {
                name = kubernetes_secret.postgres_credentials.metadata[0].name
                key  = "POSTGRES_PASSWORD"
              }
            }
          }
        ]

        # Resource configuration following your patterns
        resources = local.component_config.resources

        # Security context
        securityContext = {
          runAsNonRoot = true
          runAsUser    = 1001
          runAsGroup   = 1001
        }
      }

      # PostgreSQL configuration (if enabled)
      postgresql = local.postgresql_config

      # Ingress configuration
      ingress = local.ingress_config

      # Service configuration
      service = {
        type = "ClusterIP"
        ports = {
          backend  = 7007
          frontend = 3000
        }
      }

      # Additional security following your patterns
      podSecurityContext = {
        fsGroup = 1001
      }

      # Node selector for user nodes
      nodeSelector = {
        "kubernetes.io/os" = "linux"
      }
    })
  ]

  timeout         = 900 # 15 minutes for Backstage startup
  wait            = true
  wait_for_jobs   = true
  atomic          = true
  cleanup_on_fail = true

  depends_on = [
    kubernetes_namespace.backstage,
    kubernetes_config_map.backstage_config,
    kubernetes_secret.github_credentials,
    kubernetes_secret.postgres_credentials
  ]
}

# Outputs following your convention
output "backstage_namespace" {
  description = "Backstage namespace"
  value       = kubernetes_namespace.backstage.metadata[0].name
}

output "backstage_version" {
  description = "Deployed Backstage version"
  value       = helm_release.backstage.version
}

output "backstage_app_version" {
  description = "Backstage application version"
  value       = var.component_config.app_version
}

output "ingress_hostname" {
  description = "Backstage ingress hostname"
  value       = try(local.ingress_config.hosts[0].host, "")
}

output "helm_release_status" {
  description = "Backstage Helm release status"
  value       = helm_release.backstage.status
}
