# NGINX Ingress Controller Terraform Module Variables

variable "enabled" {
  description = "Enable or disable NGINX Ingress Controller deployment"
  type        = bool
  default     = true
}

variable "namespace" {
  description = "Kubernetes namespace for NGINX Ingress Controller"
  type        = string
  default     = "nginx-ingress"
}

variable "chart_version" {
  description = "Version of the NGINX Ingress Controller Helm chart"
  type        = string
  default     = "4.11.3"
}

# Application Configuration
variable "replica_count" {
  description = "Number of NGINX Ingress Controller replicas"
  type        = number
  default     = 2
}

variable "service_type" {
  description = "Service type for NGINX Ingress Controller"
  type        = string
  default     = "LoadBalancer"
  
  validation {
    condition     = contains(["ClusterIP", "NodePort", "LoadBalancer"], var.service_type)
    error_message = "Service type must be one of: ClusterIP, NodePort, LoadBalancer."
  }
}

variable "service_annotations" {
  description = "Annotations for the NGINX Ingress Controller service"
  type        = map(string)
  default     = {}
}

# SSL Configuration
variable "enable_ssl_redirect" {
  description = "Enable SSL redirect"
  type        = bool
  default     = true
}

variable "default_ssl_certificate" {
  description = "Default SSL certificate"
  type        = string
  default     = ""
}

# Resource Configuration
variable "resources" {
  description = "Resource requests and limits for controller"
  type = object({
    requests = object({
      cpu    = string
      memory = string
    })
    limits = object({
      cpu    = string
      memory = string
    })
  })
  default = {
    requests = {
      cpu    = "200m"
      memory = "256Mi"
    }
    limits = {
      cpu    = "1000m"
      memory = "1Gi"
    }
  }
}

variable "webhook_resources" {
  description = "Resource requests and limits for admission webhook"
  type = object({
    requests = object({
      cpu    = string
      memory = string
    })
    limits = object({
      cpu    = string
      memory = string
    })
  })
  default = {
    requests = {
      cpu    = "100m"
      memory = "128Mi"
    }
    limits = {
      cpu    = "200m"
      memory = "256Mi"
    }
  }
}

variable "security_context" {
  description = "Security context for NGINX Ingress Controller pods"
  type = object({
    runAsNonRoot             = bool
    runAsUser                = number
    runAsGroup               = number
    readOnlyRootFilesystem   = bool
    allowPrivilegeEscalation = bool
    capabilities = object({
      drop = list(string)
      add  = list(string)
    })
  })
  default = {
    runAsNonRoot             = true
    runAsUser                = 101
    runAsGroup               = 82
    readOnlyRootFilesystem   = false
    allowPrivilegeEscalation = true
    capabilities = {
      drop = ["ALL"]
      add  = ["NET_BIND_SERVICE"]
    }
  }
}

# Installation Configuration
variable "installation_timeout" {
  description = "Timeout for Helm installation in seconds"
  type        = number
  default     = 600
}

variable "atomic_installation" {
  description = "Enable atomic installation (rollback on failure)"
  type        = bool
  default     = true
}

# Monitoring Configuration
variable "metrics_enabled" {
  description = "Enable Prometheus metrics"
  type        = bool
  default     = true
}

variable "metrics_port" {
  description = "Port for Prometheus metrics"
  type        = number
  default     = 10254
}

# Node Selection
variable "node_selector" {
  description = "Node selector for NGINX Ingress Controller pods"
  type        = map(string)
  default     = {}
}

variable "tolerations" {
  description = "Tolerations for NGINX Ingress Controller pods"
  type = list(object({
    key      = string
    operator = string
    value    = string
    effect   = string
  }))
  default = []
}

variable "affinity" {
  description = "Affinity rules for NGINX Ingress Controller pods"
  type        = any
  default     = {}
}
