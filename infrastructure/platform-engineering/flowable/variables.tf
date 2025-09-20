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

variable "kubeconfig_path" {
  description = "Path to kubeconfig file for Kubernetes provider"
  type        = string
  default     = null
}

variable "component_config" {
  description = "Flowable component configuration from platform-engineering.yaml"
  type = object({
    enabled       = bool
    namespace     = optional(string, "flowable")
    chart_version = optional(string, "8.0.0")
    app_version   = optional(string, "8.0.0")
    repository    = optional(string, "https://flowable.github.io/flowable-engine")
    values        = optional(map(any), {})
  })
}

variable "flowable_hostname" {
  description = "Hostname for Flowable ingress"
  type        = string
  default     = ""
}

# Database configuration
variable "database_config" {
  description = "Database configuration for Flowable"
  type = object({
    type     = optional(string, "postgres")
    host     = optional(string, "flowable-postgresql")
    port     = optional(number, 5432)
    name     = optional(string, "flowable")
    username = optional(string, "flowable")
    password = optional(string, "flowable-dev-password")
  })
  default = {
    type     = "postgres"
    host     = "flowable-postgresql"
    port     = 5432
    name     = "flowable"
    username = "flowable"
    password = "flowable-dev-password"
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
      "nginx.ingress.kubernetes.io/ssl-redirect"       = "true"
      "nginx.ingress.kubernetes.io/force-ssl-redirect" = "true"
      "nginx.ingress.kubernetes.io/proxy-body-size"    = "50m"
      "nginx.ingress.kubernetes.io/proxy-read-timeout" = "300"
      "nginx.ingress.kubernetes.io/proxy-send-timeout" = "300"
    }
  }
}

# Vanilla Flowable setup - MSDP integration variables removed for now


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


# Vanilla Flowable setup - workflow configuration will be added later

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
