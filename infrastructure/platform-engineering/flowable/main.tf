# Flowable BPM Platform Deployment for Azure
# Following official Flowable Azure deployment guide
# https://documentation.flowable.com/latest/admin/cloud-deployment/terraform-azure

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
      
      # Environment variables for MSDP integration
      env = {
        MSDP_API_GATEWAY_URL = var.msdp_api_gateway_url
        MSDP_ORDER_SERVICE_URL = var.msdp_order_service_url
        MSDP_PAYMENT_SERVICE_URL = var.msdp_payment_service_url
        MSDP_MERCHANT_SERVICE_URL = var.msdp_merchant_service_url
        MSDP_USER_SERVICE_URL = var.msdp_user_service_url
        MSDP_ADMIN_SERVICE_URL = var.msdp_admin_service_url
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
      
      # Workflow configuration for MSDP
      workflows = var.workflow_config
    })
  ]
  
  depends_on = [kubernetes_namespace.flowable, helm_release.flowable_postgresql]
}

# MSDP Integration ConfigMap
resource "kubernetes_config_map" "flowable_msdp_config" {
  count = var.component_config.enabled ? 1 : 0
  
  metadata {
    name      = "flowable-msdp-config"
    namespace = kubernetes_namespace.flowable[0].metadata[0].name
    labels    = local.common_labels
  }
  
  data = {
    "msdp-integration.properties" = <<-EOT
      # MSDP Service Integration Configuration
      msdp.api.gateway.url=${var.msdp_api_gateway_url}
      msdp.services.order.url=${var.msdp_order_service_url}
      msdp.services.payment.url=${var.msdp_payment_service_url}
      msdp.services.merchant.url=${var.msdp_merchant_service_url}
      msdp.services.user.url=${var.msdp_user_service_url}
      msdp.services.admin.url=${var.msdp_admin_service_url}
      
      # Workflow Configuration
      msdp.workflows.order.approval.enabled=${var.workflow_config.order_approval.enabled}
      msdp.workflows.order.approval.threshold=${var.workflow_config.order_approval.approval_threshold}
      msdp.workflows.merchant.onboarding.enabled=${var.workflow_config.merchant_onboarding.enabled}
      msdp.workflows.merchant.onboarding.approval=${var.workflow_config.merchant_onboarding.approval_required}
      msdp.workflows.payment.authorization.enabled=${var.workflow_config.payment_authorization.enabled}
      msdp.workflows.payment.authorization.threshold=${var.workflow_config.payment_authorization.amount_threshold}
    EOT
  }
}

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
