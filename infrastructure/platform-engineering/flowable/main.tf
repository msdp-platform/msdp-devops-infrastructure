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

# Flowable Helm release using official approach
resource "helm_release" "flowable" {
  count = var.component_config.enabled ? 1 : 0
  
  name       = "flowable"
  repository = "https://flowable.github.io/flowable-engine"
  chart      = "flowable"
  version    = var.component_config.chart_version
  namespace  = kubernetes_namespace.flowable[0].metadata[0].name
  
  # Flowable values following Azure deployment guide
  values = [
    yamlencode({
      # Image configuration
      image = {
        repository = "flowable/all-in-one"
        tag        = var.component_config.app_version
        pullPolicy = "IfNotPresent"
      }
      
      # Service configuration
      service = {
        type = "ClusterIP"
        port = 80
        targetPort = 8080
      }
      
      # Database configuration
      database = {
        type     = local.flowable_config.database.type
        host     = "flowable-postgresql"
        port     = local.flowable_config.database.port
        name     = local.flowable_config.database.name
        username = local.flowable_config.database.username
        password = local.flowable_config.database.password
      }
      
      # Ingress configuration
      ingress = {
        enabled = var.ingress_config.enabled
        className = var.ingress_config.class_name
        annotations = merge(var.ingress_config.annotations, {
          "cert-manager.io/cluster-issuer" = var.ingress_config.cluster_issuer_name
        })
        hosts = [{
          host = var.flowable_hostname
          paths = [{
            path = "/"
            pathType = "Prefix"
          }]
        }]
        tls = [{
          secretName = "flowable-tls"
          hosts = [var.flowable_hostname]
        }]
      }
      
      # Resources
      resources = var.resources.flowable
      
      # Environment variables (vanilla setup)
      env = {
        # Basic Flowable configuration
        FLOWABLE_DATABASE_TYPE = local.flowable_config.database.type
        FLOWABLE_DATABASE_HOST = local.flowable_config.database.host
        FLOWABLE_DATABASE_PORT = tostring(local.flowable_config.database.port)
        FLOWABLE_DATABASE_NAME = local.flowable_config.database.name
        FLOWABLE_DATABASE_USERNAME = local.flowable_config.database.username
        FLOWABLE_DATABASE_PASSWORD = local.flowable_config.database.password
      }
      
      # Health checks
      livenessProbe = {
        httpGet = {
          path = "/flowable-ui"
          port = 8080
        }
        initialDelaySeconds = 120
        periodSeconds = 30
        timeoutSeconds = 10
        failureThreshold = 3
      }
      
      readinessProbe = {
        httpGet = {
          path = "/flowable-ui"
          port = 8080
        }
        initialDelaySeconds = 60
        periodSeconds = 10
        timeoutSeconds = 5
        failureThreshold = 3
      }
      
      # Basic Flowable configuration (vanilla setup)
      # No custom workflows - using default Flowable setup
    })
  ]
  
  depends_on = [kubernetes_namespace.flowable, helm_release.flowable_postgresql]
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

output "flowable_release_name" {
  description = "Flowable Helm release name"
  value       = var.component_config.enabled ? helm_release.flowable[0].name : null
}

output "database_release_name" {
  description = "Flowable database Helm release name"
  value       = var.component_config.enabled ? helm_release.flowable_postgresql[0].name : null
}

output "flowable_version" {
  description = "Deployed Flowable version"
  value       = var.component_config.enabled ? var.component_config.app_version : null
}
