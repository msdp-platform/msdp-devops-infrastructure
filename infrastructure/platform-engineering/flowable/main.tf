# Flowable BPM Platform Deployment
# Business Process Management and Workflow Automation for MSDP

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

# Flowable namespace
resource "kubernetes_namespace" "flowable" {
  count = var.component_config.enabled ? 1 : 0
  
  metadata {
    name = var.namespace
    
    labels = {
      "app.kubernetes.io/name"       = "flowable"
      "app.kubernetes.io/instance"   = "flowable-${var.environment}"
      "app.kubernetes.io/component"  = "bpm-platform"
      "app.kubernetes.io/part-of"    = "msdp-platform"
      "app.kubernetes.io/managed-by" = "terraform"
    }
  }
}

# PostgreSQL database for Flowable (using existing MSDP pattern)
resource "kubernetes_deployment" "flowable_postgres" {
  count = var.component_config.enabled ? 1 : 0
  
  metadata {
    name      = "flowable-postgres"
    namespace = kubernetes_namespace.flowable[0].metadata[0].name
    
    labels = {
      app = "flowable-postgres"
    }
  }
  
  spec {
    replicas = 1
    
    selector {
      match_labels = {
        app = "flowable-postgres"
      }
    }
    
    template {
      metadata {
        labels = {
          app = "flowable-postgres"
        }
      }
      
      spec {
        container {
          name  = "postgres"
          image = "postgres:15-alpine"
          
          port {
            container_port = 5432
          }
          
          env {
            name  = "POSTGRES_DB"
            value = "flowable"
          }
          
          env {
            name  = "POSTGRES_USER"
            value = "flowable"
          }
          
          env {
            name  = "POSTGRES_PASSWORD"
            value = "flowable-dev-password"
          }
          
          volume_mount {
            name       = "postgres-data"
            mount_path = "/var/lib/postgresql/data"
          }
          
          resources {
            requests = {
              memory = "256Mi"
              cpu    = "250m"
            }
            limits = {
              memory = "512Mi"
              cpu    = "500m"
            }
          }
        }
        
        volume {
          name = "postgres-data"
          empty_dir {}
        }
      }
    }
  }
}

# PostgreSQL service
resource "kubernetes_service" "flowable_postgres" {
  count = var.component_config.enabled ? 1 : 0
  
  metadata {
    name      = "flowable-postgres"
    namespace = kubernetes_namespace.flowable[0].metadata[0].name
  }
  
  spec {
    selector = {
      app = "flowable-postgres"
    }
    
    port {
      port        = 5432
      target_port = 5432
    }
  }
}

# Flowable All-in-One deployment
resource "kubernetes_deployment" "flowable" {
  count = var.component_config.enabled ? 1 : 0
  
  depends_on = [kubernetes_service.flowable_postgres]
  
  metadata {
    name      = "flowable"
    namespace = kubernetes_namespace.flowable[0].metadata[0].name
    
    labels = {
      app = "flowable"
    }
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
        labels = {
          app = "flowable"
        }
      }
      
      spec {
        container {
          name  = "flowable"
          image = "flowable/all-in-one:7.2.0"
          
          port {
            container_port = 8080
          }
          
          env {
            name  = "FLOWABLE_DATABASE_TYPE"
            value = "postgres"
          }
          
          env {
            name  = "FLOWABLE_DATABASE_HOST"
            value = "flowable-postgres"
          }
          
          env {
            name  = "FLOWABLE_DATABASE_PORT"
            value = "5432"
          }
          
          env {
            name  = "FLOWABLE_DATABASE_NAME"
            value = "flowable"
          }
          
          env {
            name  = "FLOWABLE_DATABASE_USERNAME"
            value = "flowable"
          }
          
          env {
            name  = "FLOWABLE_DATABASE_PASSWORD"
            value = "flowable-dev-password"
          }
          
          # MSDP Integration endpoints
          env {
            name  = "MSDP_API_GATEWAY_URL"
            value = var.msdp_api_gateway_url
          }
          
          env {
            name  = "MSDP_ORDER_SERVICE_URL"
            value = var.msdp_order_service_url
          }
          
          env {
            name  = "MSDP_PAYMENT_SERVICE_URL"
            value = var.msdp_payment_service_url
          }
          
          env {
            name  = "MSDP_MERCHANT_SERVICE_URL"
            value = var.msdp_merchant_service_url
          }
          
          resources {
            requests = {
              memory = "1Gi"
              cpu    = "500m"
            }
            limits = {
              memory = "2Gi"
              cpu    = "1000m"
            }
          }
          
          liveness_probe {
            http_get {
              path = "/flowable-ui/"
              port = 8080
            }
            initial_delay_seconds = 120
            period_seconds        = 30
          }
          
          readiness_probe {
            http_get {
              path = "/flowable-ui/"
              port = 8080
            }
            initial_delay_seconds = 60
            period_seconds        = 10
          }
        }
      }
    }
  }
}

# Flowable service
resource "kubernetes_service" "flowable" {
  count = var.component_config.enabled ? 1 : 0
  
  metadata {
    name      = "flowable"
    namespace = kubernetes_namespace.flowable[0].metadata[0].name
  }
  
  spec {
    selector = {
      app = "flowable"
    }
    
    port {
      port        = 8080
      target_port = 8080
    }
  }
}

# Flowable ingress
resource "kubernetes_ingress_v1" "flowable" {
  count = var.component_config.enabled ? 1 : 0
  
  metadata {
    name      = "flowable"
    namespace = kubernetes_namespace.flowable[0].metadata[0].name
    
    annotations = {
      "kubernetes.io/ingress.class"                    = "nginx"
      "cert-manager.io/cluster-issuer"                 = "letsencrypt-prod"
      "nginx.ingress.kubernetes.io/ssl-redirect"       = "true"
      "nginx.ingress.kubernetes.io/force-ssl-redirect" = "true"
      "nginx.ingress.kubernetes.io/proxy-body-size"    = "50m"
      "nginx.ingress.kubernetes.io/proxy-read-timeout" = "300"
      "nginx.ingress.kubernetes.io/proxy-send-timeout" = "300"
    }
  }
  
  spec {
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
                number = 8080
              }
            }
          }
        }
      }
    }
  }
}

# ConfigMap for Flowable MSDP integration
resource "kubernetes_config_map" "flowable_msdp_config" {
  count = var.component_config.enabled ? 1 : 0
  
  metadata {
    name      = "flowable-msdp-config"
    namespace = kubernetes_namespace.flowable[0].metadata[0].name
  }
  
  data = {
    "msdp-integration.properties" = <<-EOT
      # MSDP Platform Integration Configuration
      msdp.api.gateway.url=${var.msdp_api_gateway_url}
      msdp.services.order.url=${var.msdp_order_service_url}
      msdp.services.payment.url=${var.msdp_payment_service_url}
      msdp.services.merchant.url=${var.msdp_merchant_service_url}
      msdp.services.user.url=${var.msdp_user_service_url}
      
      # Workflow configurations
      msdp.workflows.order.approval.enabled=true
      msdp.workflows.merchant.onboarding.enabled=true
      msdp.workflows.payment.authorization.enabled=true
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

output "flowable_service_name" {
  description = "Flowable service name"
  value       = var.component_config.enabled ? kubernetes_service.flowable[0].metadata[0].name : null
}

output "database_service_name" {
  description = "Flowable database service name"
  value       = var.component_config.enabled ? kubernetes_service.flowable_postgres[0].metadata[0].name : null
}
