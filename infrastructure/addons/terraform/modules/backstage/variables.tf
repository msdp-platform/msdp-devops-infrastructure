# Backstage Module Variables
# Following MSDP addon patterns

variable "enabled" {
  description = "Enable Backstage deployment"
  type        = bool
  default     = false
}

variable "environment" {
  description = "Environment name (dev, staging, prod)"
  type        = string
  default     = "dev"
}

variable "namespace" {
  description = "Kubernetes namespace for Backstage"
  type        = string
  default     = "backstage"
}

variable "chart_version" {
  description = "Backstage Helm chart version"
  type        = string
  default     = "1.8.3"
}

variable "backstage_version" {
  description = "Backstage application version"
  type        = string
  default     = "latest"
}

variable "hostname" {
  description = "Backstage ingress hostname"
  type        = string
  default     = ""
}

variable "ingress_class_name" {
  description = "Ingress class name"
  type        = string
  default     = "nginx"
}

variable "cluster_issuer_name" {
  description = "Cert-manager cluster issuer name"
  type        = string
  default     = ""
}

variable "tls_secret_name" {
  description = "TLS secret name for ingress"
  type        = string
  default     = ""
}

variable "additional_ingress_annotations" {
  description = "Additional annotations for ingress"
  type        = map(string)
  default     = {}
}

variable "installation_timeout" {
  description = "Timeout for Helm installation in seconds"
  type        = number
  default     = 900
}

variable "app_config" {
  description = "Backstage app configuration"
  type        = any
  default     = {}
}

variable "ingress" {
  description = "Ingress configuration"
  type = object({
    enabled = bool
  })
  default = {
    enabled = true
  }
}

variable "postgresql" {
  description = "PostgreSQL configuration"
  type = object({
    enabled = bool
    auth = object({
      username = string
      password = string
      database = string
    })
  })
  default = {
    enabled = true
    auth = {
      username = "backstage"
      password = "backstage-password"
      database = "backstage"
    }
  }
}

variable "external_postgres_host" {
  description = "External PostgreSQL host (if not using embedded PostgreSQL)"
  type        = string
  default     = ""
}

variable "resources" {
  description = "Resource requests and limits for Backstage"
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
      cpu    = "250m"
      memory = "512Mi"
    }
    limits = {
      cpu    = "1000m"
      memory = "1Gi"
    }
  }
}

# GitHub integration variables
variable "github_client_id" {
  description = "GitHub OAuth client ID for Backstage authentication"
  type        = string
  default     = ""
  sensitive   = true
}

variable "github_client_secret" {
  description = "GitHub OAuth client secret for Backstage authentication"
  type        = string
  default     = ""
  sensitive   = true
}

variable "github_token" {
  description = "GitHub token for Backstage to access repositories"
  type        = string
  default     = ""
  sensitive   = true
}
