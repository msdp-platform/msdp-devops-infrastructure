# Flowable BPM Platform Variables

variable "cluster_name" {
  description = "Kubernetes cluster name"
  type        = string
}

variable "environment" {
  description = "Environment name (dev, staging, prod)"
  type        = string
}

variable "location" {
  description = "Azure location"
  type        = string
}

variable "namespace" {
  description = "Kubernetes namespace for Flowable"
  type        = string
  default     = "flowable"
}

variable "component_config" {
  description = "Flowable component configuration from platform-engineering.yaml"
  type = object({
    enabled       = bool
    namespace     = optional(string, "flowable")
    chart_version = optional(string, "7.2.0")
    app_version   = optional(string, "7.2.0")
    values        = optional(map(any), {})
  })
}

variable "flowable_hostname" {
  description = "Hostname for Flowable ingress"
  type        = string
  default     = ""
}

# MSDP Integration URLs
variable "msdp_api_gateway_url" {
  description = "MSDP API Gateway URL for Flowable integration"
  type        = string
  default     = "http://api-gateway:3000"
}

variable "msdp_order_service_url" {
  description = "MSDP Order Service URL for workflow integration"
  type        = string
  default     = "http://order-service:3006"
}

variable "msdp_payment_service_url" {
  description = "MSDP Payment Service URL for workflow integration"
  type        = string
  default     = "http://payment-service:3007"
}

variable "msdp_merchant_service_url" {
  description = "MSDP Merchant Service URL for workflow integration"
  type        = string
  default     = "http://merchant-service:3002"
}

variable "msdp_user_service_url" {
  description = "MSDP User Service URL for workflow integration"
  type        = string
  default     = "http://user-service:3003"
}

variable "msdp_admin_service_url" {
  description = "MSDP Admin Service URL for workflow integration"
  type        = string
  default     = "http://admin-service:3005"
}

# Database configuration
variable "database_config" {
  description = "Database configuration for Flowable"
  type = object({
    type     = optional(string, "postgres")
    host     = optional(string, "flowable-postgres")
    port     = optional(number, 5432)
    name     = optional(string, "flowable")
    username = optional(string, "flowable")
    password = optional(string, "flowable-dev-password")
  })
  default = {
    type     = "postgres"
    host     = "flowable-postgres"
    port     = 5432
    name     = "flowable"
    username = "flowable"
    password = "flowable-dev-password"
  }
}

# Resource configuration
variable "resources" {
  description = "Resource configuration for Flowable components"
  type = object({
    flowable = optional(object({
      requests = optional(object({
        cpu    = optional(string, "500m")
        memory = optional(string, "1Gi")
      }), {})
      limits = optional(object({
        cpu    = optional(string, "1000m")
        memory = optional(string, "2Gi")
      }), {})
    }), {})
    postgres = optional(object({
      requests = optional(object({
        cpu    = optional(string, "250m")
        memory = optional(string, "256Mi")
      }), {})
      limits = optional(object({
        cpu    = optional(string, "500m")
        memory = optional(string, "512Mi")
      }), {})
    }), {})
  })
  default = {
    flowable = {
      requests = {
        cpu    = "500m"
        memory = "1Gi"
      }
      limits = {
        cpu    = "1000m"
        memory = "2Gi"
      }
    }
    postgres = {
      requests = {
        cpu    = "250m"
        memory = "256Mi"
      }
      limits = {
        cpu    = "500m"
        memory = "512Mi"
      }
    }
  }
}

# Ingress configuration
variable "ingress_config" {
  description = "Ingress configuration for Flowable"
  type = object({
    enabled             = optional(bool, true)
    class_name          = optional(string, "nginx")
    cluster_issuer_name = optional(string, "letsencrypt-prod")
    annotations         = optional(map(string), {})
  })
  default = {
    enabled             = true
    class_name          = "nginx"
    cluster_issuer_name = "letsencrypt-prod"
    annotations = {
      "nginx.ingress.kubernetes.io/proxy-body-size"    = "50m"
      "nginx.ingress.kubernetes.io/proxy-read-timeout" = "300"
      "nginx.ingress.kubernetes.io/proxy-send-timeout" = "300"
    }
  }
}

# Workflow configuration
variable "workflow_config" {
  description = "Flowable workflow configuration for MSDP processes"
  type = object({
    order_approval = optional(object({
      enabled                = optional(bool, true)
      approval_threshold     = optional(number, 1000)
      auto_approve_merchants = optional(list(string), [])
    }), {})
    merchant_onboarding = optional(object({
      enabled              = optional(bool, true)
      verification_steps   = optional(list(string), ["identity", "business", "financial"])
      approval_required    = optional(bool, true)
    }), {})
    payment_authorization = optional(object({
      enabled            = optional(bool, true)
      amount_threshold   = optional(number, 5000)
      multi_step_approval = optional(bool, true)
    }), {})
  })
  default = {
    order_approval = {
      enabled                = true
      approval_threshold     = 1000
      auto_approve_merchants = []
    }
    merchant_onboarding = {
      enabled              = true
      verification_steps   = ["identity", "business", "financial"]
      approval_required    = true
    }
    payment_authorization = {
      enabled            = true
      amount_threshold   = 5000
      multi_step_approval = true
    }
  }
}

# Tags
variable "tags" {
  description = "Tags to apply to all resources"
  type        = map(string)
  default = {
    Component   = "flowable"
    ManagedBy   = "terraform"
    Environment = "dev"
  }
}
