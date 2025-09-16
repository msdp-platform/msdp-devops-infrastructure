# Azure Disk CSI Driver Terraform Module Variables

variable "enabled" {
  description = "Enable or disable Azure Disk CSI Driver deployment"
  type        = bool
  default     = true
}

variable "namespace" {
  description = "Kubernetes namespace for Azure Disk CSI Driver"
  type        = string
  default     = "kube-system"
}

variable "chart_version" {
  description = "Version of the Azure Disk CSI Driver Helm chart"
  type        = string
  default     = "v1.29.2"
}

# Storage Configuration
variable "create_storage_classes" {
  description = "Create default storage classes"
  type        = bool
  default     = true
}

variable "default_storage_class" {
  description = "Default storage class name"
  type        = string
  default     = "managed-premium"
  
  validation {
    condition     = contains(["managed-premium", "managed-standard"], var.default_storage_class)
    error_message = "Default storage class must be either 'managed-premium' or 'managed-standard'."
  }
}

variable "enable_encryption" {
  description = "Enable disk encryption"
  type        = bool
  default     = true
}

# Resource Configuration
variable "controller_resources" {
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
      cpu    = "100m"
      memory = "128Mi"
    }
    limits = {
      cpu    = "500m"
      memory = "512Mi"
    }
  }
}

variable "node_resources" {
  description = "Resource requests and limits for node driver"
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
      cpu    = "50m"
      memory = "64Mi"
    }
    limits = {
      cpu    = "200m"
      memory = "256Mi"
    }
  }
}

variable "security_context" {
  description = "Security context for Azure Disk CSI Driver pods"
  type = object({
    runAsNonRoot             = bool
    runAsUser                = number
    readOnlyRootFilesystem   = bool
    allowPrivilegeEscalation = bool
    capabilities = object({
      drop = list(string)
    })
  })
  default = {
    runAsNonRoot             = false
    runAsUser                = 0
    readOnlyRootFilesystem   = true
    allowPrivilegeEscalation = true
    capabilities = {
      drop = ["ALL"]
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
  default     = 29604
}

# Node Selection
variable "node_selector" {
  description = "Node selector for Azure Disk CSI Driver pods"
  type        = map(string)
  default     = {}
}

variable "tolerations" {
  description = "Tolerations for Azure Disk CSI Driver pods"
  type = list(object({
    key      = string
    operator = string
    value    = string
    effect   = string
  }))
  default = []
}