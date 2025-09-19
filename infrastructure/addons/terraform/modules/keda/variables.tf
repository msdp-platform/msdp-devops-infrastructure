# KEDA Terraform Module Variables

variable "enabled" {
  description = "Enable or disable KEDA deployment"
  type        = bool
  default     = true
}

variable "namespace" {
  description = "Kubernetes namespace for KEDA"
  type        = string
  default     = "keda"
}


# Azure Configuration
variable "azure_subscription_id" {
  description = "Azure subscription ID"
  type        = string
  default     = ""
}

variable "azure_resource_group" {
  description = "Azure resource group name"
  type        = string
  default     = ""
}

# Application Configuration
variable "log_level" {
  description = "Log level for KEDA"
  type        = string
  default     = "info"
  
  validation {
    condition     = contains(["debug", "info", "warn", "error"], var.log_level)
    error_message = "Log level must be one of: debug, info, warn, error."
  }
}

variable "resources" {
  description = "Resource requests and limits"
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
      cpu    = "1000m"
      memory = "1Gi"
    }
  }
}

variable "security_context" {
  description = "Security context for KEDA pods"
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
    runAsNonRoot             = true
    runAsUser                = 1001
    readOnlyRootFilesystem   = true
    allowPrivilegeEscalation = false
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
  default     = 8080
}