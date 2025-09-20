# Flowable BPM Platform Deployment for Azure
# Following official Flowable Azure deployment guide
# https://documentation.flowable.com/latest/admin/cloud-deployment/terraform-azure

terraform {
  required_version = ">= 1.5"
  
  required_providers {
    helm = {
      source  = "hashicorp/helm"
      version = "~> 2.15"
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

# Local configuration
locals {
  namespace = var.namespace
  
  common_labels = {
    "app.kubernetes.io/name"       = "flowable"
    "app.kubernetes.io/instance"   = "flowable-${var.environment}"
    "app.kubernetes.io/component"  = "bpm-platform"
    "app.kubernetes.io/part-of"    = "msdp-platform"
    "app.kubernetes.io/managed-by" = "terraform"
  }
  
  # Flowable configuration based on Azure best practices
  flowable_config = {
    image = {
      repository = "flowable/flowable-ui"
      tag        = var.component_config.app_version
    }
    database = {
      type     = var.database_config.type
      host     = var.database_config.host
      port     = var.database_config.port
      name     = var.database_config.name
      username = var.database_config.username
      password = var.database_config.password
    }
  }
}

# Flowable namespace
resource "kubernetes_namespace" "flowable" {
  count = var.component_config.enabled ? 1 : 0
  
  metadata {
    name   = local.namespace
    labels = local.common_labels
  }
}

# PostgreSQL Helm chart for Flowable database
resource "helm_release" "flowable_postgresql" {
  count = var.component_config.enabled ? 1 : 0
  
  name       = "flowable-postgresql"
  repository = "https://charts.bitnami.com/bitnami"
  chart      = "postgresql"
  version    = "12.1.9"
  namespace  = kubernetes_namespace.flowable[0].metadata[0].name
  
  values = [
    yamlencode({
      auth = {
        postgresPassword = local.flowable_config.database.password
        username         = local.flowable_config.database.username
        password         = local.flowable_config.database.password
        database         = local.flowable_config.database.name
      }
      
      primary = {
        resources = var.resources.postgres
        
        persistence = {
          enabled = true
          size    = "10Gi"
        }
      }
      
      metrics = {
        enabled = true
        serviceMonitor = {
          enabled = true
        }
      }
    })
  ]
  
  depends_on = [kubernetes_namespace.flowable]
}

# Flowable Deployment (using Kubernetes resources since no official Helm chart)
resource "kubernetes_deployment" "flowable" {
  count = var.component_config.enabled ? 1 : 0

  metadata {
    name      = "flowable"
    namespace = kubernetes_namespace.flowable[0].metadata[0].name
    labels    = local.common_labels
  }

  spec {
    replicas = 1

    selector {
      match_labels = {
        app = "flowable"
      }
    }

    template {
      metadata {
        labels = merge(local.common_labels, {
          app = "flowable"
        })
      }

      spec {
        container {
          name  = "flowable"
          image = "flowable/all-in-one:${var.component_config.app_version}"

          port {
            container_port = 8080
            name          = "http"
          }

          env {
            name  = "FLOWABLE_DATABASE_TYPE"
            value = local.flowable_config.database.type
          }
          env {
            name  = "FLOWABLE_DATABASE_HOST"
            value = local.flowable_config.database.host
          }
          env {
            name  = "FLOWABLE_DATABASE_PORT"
            value = tostring(local.flowable_config.database.port)
          }
          env {
            name  = "FLOWABLE_DATABASE_NAME"
            value = local.flowable_config.database.name
          }
          env {
            name  = "FLOWABLE_DATABASE_USERNAME"
            value = local.flowable_config.database.username
          }
          env {
            name  = "FLOWABLE_DATABASE_PASSWORD"
            value = local.flowable_config.database.password
          }

          resources {
            requests = {
              cpu    = var.resources.flowable.requests.cpu
              memory = var.resources.flowable.requests.memory
            }
            limits = {
              cpu    = var.resources.flowable.limits.cpu
              memory = var.resources.flowable.limits.memory
            }
          }

          liveness_probe {
            http_get {
              path = "/flowable-ui"
              port = 8080
            }
            initial_delay_seconds = 120
            period_seconds        = 30
            timeout_seconds       = 10
            failure_threshold     = 5
          }

          readiness_probe {
            http_get {
              path = "/flowable-ui"
              port = 8080
            }
            initial_delay_seconds = 60
            period_seconds        = 10
            timeout_seconds       = 5
            failure_threshold     = 3
          }
        }
      }
    }
  }

  depends_on = [kubernetes_namespace.flowable, helm_release.flowable_postgresql]
}

# Flowable Service
resource "kubernetes_service" "flowable" {
  count = var.component_config.enabled ? 1 : 0

  metadata {
    name      = "flowable"
    namespace = kubernetes_namespace.flowable[0].metadata[0].name
    labels    = local.common_labels
  }

  spec {
    selector = {
      app = "flowable"
    }

    port {
      name        = "http"
      port        = 80
      target_port = 8080
      protocol    = "TCP"
    }

    type = "ClusterIP"
  }
}

# Flowable Ingress
resource "kubernetes_ingress_v1" "flowable" {
  count = var.component_config.enabled ? 1 : 0

  metadata {
    name      = "flowable"
    namespace = kubernetes_namespace.flowable[0].metadata[0].name
    labels    = local.common_labels
    annotations = {
      "cert-manager.io/cluster-issuer"                = "letsencrypt-prod"
      "nginx.ingress.kubernetes.io/ssl-redirect"      = "true"
      "nginx.ingress.kubernetes.io/force-ssl-redirect" = "true"
      "nginx.ingress.kubernetes.io/proxy-body-size"   = "50m"
      "nginx.ingress.kubernetes.io/proxy-read-timeout" = "300"
      "nginx.ingress.kubernetes.io/proxy-send-timeout" = "300"
    }
  }

  spec {
    ingress_class_name = "nginx"

    tls {
      hosts       = [var.flowable_hostname]
      secret_name = "flowable-tls"
    }

    rule {
      host = var.flowable_hostname

      http {
        path {
          path      = "/"
          path_type = "Prefix"

          backend {
            service {
              name = kubernetes_service.flowable[0].metadata[0].name
              port {
                number = 80
              }
            }
          }
        }
      }
    }
  }
}

# Vanilla Flowable setup - no custom integrations for now

# Outputs
output "namespace" {
  description = "Flowable namespace"
  value       = var.component_config.enabled ? kubernetes_namespace.flowable[0].metadata[0].name : null
}
output "flowable_url" {
  description = "Flowable access URL"
  value       = var.component_config.enabled ? "https://${var.flowable_hostname}" : null
}

output "flowable_deployment_name" {
  description = "Flowable Kubernetes deployment name"
  value       = var.component_config.enabled ? kubernetes_deployment.flowable[0].metadata[0].name : null
}

output "database_release_name" {
  description = "Flowable database Helm release name"
  value       = var.component_config.enabled ? helm_release.flowable_postgresql[0].name : null
}

output "flowable_version" {
  description = "Deployed Flowable version"
  value       = var.component_config.enabled ? var.component_config.app_version : null
}
