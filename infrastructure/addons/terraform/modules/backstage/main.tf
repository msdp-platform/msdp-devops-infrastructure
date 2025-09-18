# Backstage Terraform Module
# Follows MSDP addon patterns and integrates with existing infrastructure

terraform {
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

# Backstage namespace
resource "kubernetes_namespace" "backstage" {
  count = var.enabled ? 1 : 0

  metadata {
    name = var.namespace
    labels = {
      "app.kubernetes.io/name"       = "backstage"
      "app.kubernetes.io/managed-by" = "terraform"
      "app.kubernetes.io/component"  = "developer-portal"
      "app.kubernetes.io/part-of"    = "msdp-platform"
      "msdp.platform/component"      = "backstage"
      "msdp.platform/environment"    = var.environment
    }
  }
}

# Backstage app configuration
resource "kubernetes_config_map" "backstage_config" {
  count = var.enabled ? 1 : 0

  metadata {
    name      = "backstage-app-config"
    namespace = kubernetes_namespace.backstage[0].metadata[0].name
    labels = {
      "app.kubernetes.io/name"      = "backstage"
      "app.kubernetes.io/component" = "config"
      "msdp.platform/component"     = "backstage"
    }
  }

  data = {
    "app-config.yaml" = yamlencode(var.app_config)
  }
}

# GitHub credentials secret
resource "kubernetes_secret" "github_credentials" {
  count = var.enabled ? 1 : 0

  metadata {
    name      = "github-credentials"
    namespace = kubernetes_namespace.backstage[0].metadata[0].name
    labels = {
      "app.kubernetes.io/name"      = "backstage"
      "app.kubernetes.io/component" = "credentials"
      "msdp.platform/component"     = "backstage"
    }
  }

  data = {
    GITHUB_CLIENT_ID     = var.github_client_id
    GITHUB_CLIENT_SECRET = var.github_client_secret
    GITHUB_TOKEN         = var.github_token
  }

  type = "Opaque"
}

# PostgreSQL credentials secret
resource "kubernetes_secret" "postgres_credentials" {
  count = var.enabled ? 1 : 0

  metadata {
    name      = "postgres-credentials"
    namespace = kubernetes_namespace.backstage[0].metadata[0].name
    labels = {
      "app.kubernetes.io/name"      = "backstage"
      "app.kubernetes.io/component" = "database-credentials"
      "msdp.platform/component"     = "backstage"
    }
  }

  data = {
    POSTGRES_HOST     = var.postgresql.enabled ? "backstage-postgresql" : var.external_postgres_host
    POSTGRES_PORT     = "5432"
    POSTGRES_USER     = var.postgresql.auth.username
    POSTGRES_PASSWORD = var.postgresql.auth.password
    POSTGRES_DB       = var.postgresql.auth.database
  }

  type = "Opaque"
}

# Local values for ingress annotations
locals {
  ingress_annotations = merge(
    var.cluster_issuer_name != "" ? {
      "cert-manager.io/cluster-issuer" = var.cluster_issuer_name
    } : {},
    var.additional_ingress_annotations
  )
}

# Backstage Helm release
resource "helm_release" "backstage" {
  count = var.enabled ? 1 : 0

  name       = "backstage"
  repository = "https://backstage.github.io/charts"
  chart      = "backstage"
  version    = var.chart_version
  namespace  = kubernetes_namespace.backstage[0].metadata[0].name

  values = [
    yamlencode({
      # Backstage configuration
      backstage = {
        image = {
          repository = "backstage/backstage"
          tag        = var.backstage_version
        }

        # App configuration via ConfigMap
        appConfig = {
          configMapRef = kubernetes_config_map.backstage_config[0].metadata[0].name
        }

        # Environment variables from secrets
        extraEnvVars = [
          {
            name = "GITHUB_CLIENT_ID"
            valueFrom = {
              secretKeyRef = {
                name = kubernetes_secret.github_credentials[0].metadata[0].name
                key  = "GITHUB_CLIENT_ID"
              }
            }
          },
          {
            name = "GITHUB_CLIENT_SECRET"
            valueFrom = {
              secretKeyRef = {
                name = kubernetes_secret.github_credentials[0].metadata[0].name
                key  = "GITHUB_CLIENT_SECRET"
              }
            }
          },
          {
            name = "GITHUB_TOKEN"
            valueFrom = {
              secretKeyRef = {
                name = kubernetes_secret.github_credentials[0].metadata[0].name
                key  = "GITHUB_TOKEN"
              }
            }
          },
          {
            name = "POSTGRES_HOST"
            valueFrom = {
              secretKeyRef = {
                name = kubernetes_secret.postgres_credentials[0].metadata[0].name
                key  = "POSTGRES_HOST"
              }
            }
          },
          {
            name = "POSTGRES_PORT"
            valueFrom = {
              secretKeyRef = {
                name = kubernetes_secret.postgres_credentials[0].metadata[0].name
                key  = "POSTGRES_PORT"
              }
            }
          },
          {
            name = "POSTGRES_USER"
            valueFrom = {
              secretKeyRef = {
                name = kubernetes_secret.postgres_credentials[0].metadata[0].name
                key  = "POSTGRES_USER"
              }
            }
          },
          {
            name = "POSTGRES_PASSWORD"
            valueFrom = {
              secretKeyRef = {
                name = kubernetes_secret.postgres_credentials[0].metadata[0].name
                key  = "POSTGRES_PASSWORD"
              }
            }
          },
          {
            name = "POSTGRES_DB"
            valueFrom = {
              secretKeyRef = {
                name = kubernetes_secret.postgres_credentials[0].metadata[0].name
                key  = "POSTGRES_DB"
              }
            }
          }
        ]

        # Resource configuration following your patterns
        resources = var.resources

        # Security context
        securityContext = {
          runAsNonRoot = true
          runAsUser    = 1001
          runAsGroup   = 1001
        }

        # Node selector for user nodes (following your AKS patterns)
        nodeSelector = {
          "kubernetes.io/os" = "linux"
        }

        # Probes
        livenessProbe = {
          httpGet = {
            path = "/healthcheck"
            port = 7007
          }
          initialDelaySeconds = 60
          periodSeconds       = 10
          timeoutSeconds      = 2
          failureThreshold    = 3
          successThreshold    = 1
        }

        readinessProbe = {
          httpGet = {
            path = "/healthcheck"
            port = 7007
          }
          initialDelaySeconds = 30
          periodSeconds       = 10
          timeoutSeconds      = 2
          failureThreshold    = 3
          successThreshold    = 1
        }
      }

      # PostgreSQL configuration (if enabled)
      postgresql = var.postgresql

      # Ingress configuration following your patterns
      ingress = {
        enabled     = var.ingress.enabled
        className   = var.ingress_class_name
        annotations = local.ingress_annotations
        hosts = [
          {
            host = var.hostname
            paths = [
              {
                path     = "/"
                pathType = "Prefix"
              }
            ]
          }
        ]
        tls = var.tls_secret_name != "" ? [
          {
            secretName = var.tls_secret_name
            hosts      = [var.hostname]
          }
        ] : []
      }

      # Service configuration
      service = {
        type = "ClusterIP"
        ports = {
          backend = {
            port       = 7007
            targetPort = "backend"
            protocol   = "TCP"
          }
          frontend = {
            port       = 3000
            targetPort = "frontend"
            protocol   = "TCP"
          }
        }
      }

      # Pod security context
      podSecurityContext = {
        fsGroup = 1001
      }

      # Service account
      serviceAccount = {
        create = true
        name   = "backstage"
        annotations = {
          "app.kubernetes.io/managed-by" = "terraform"
        }
      }
    })
  ]

  timeout         = var.installation_timeout
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
output "namespace" {
  description = "Namespace where Backstage is deployed"
  value       = var.enabled ? kubernetes_namespace.backstage[0].metadata[0].name : null
}

output "helm_release_status" {
  description = "Status of the Backstage Helm release"
  value       = var.enabled ? helm_release.backstage[0].status : null
}

output "helm_release_version" {
  description = "Version of the deployed Helm chart"
  value       = var.enabled ? helm_release.backstage[0].version : null
}

output "hostname" {
  description = "Backstage ingress hostname"
  value       = var.enabled ? var.hostname : null
}

output "app_version" {
  description = "Backstage application version"
  value       = var.enabled ? var.backstage_version : null
}
