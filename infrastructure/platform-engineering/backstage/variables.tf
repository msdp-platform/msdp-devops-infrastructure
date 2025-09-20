# Backstage Terraform Variables

variable "cluster_name" {
  description = "Name of the AKS cluster"
  type        = string
}

variable "environment" {
  description = "Environment (dev, staging, prod)"
  type        = string
  validation {
    condition     = contains(["dev", "staging", "prod", "sandbox"], var.environment)
    error_message = "Environment must be one of: dev, staging, prod, sandbox."
  }
}

variable "location" {
  description = "Azure region"
  type        = string
  default     = "uksouth"
}

variable "component_config" {
  description = "Backstage component configuration from platform-engineering.yaml"
  type = object({
    enabled       = bool
    namespace     = string
    chart_version = string
    app_version   = string
    repository    = string
    app_config    = any
    postgresql = object({
      enabled = bool
      auth = object({
        username = string
        password = string
        database = string
      })
      primary = object({
        persistence = object({
          enabled      = bool
          size         = string
          storageClass = string
        })
        resources = object({
          requests = object({
            memory = string
            cpu    = string
          })
          limits = object({
            memory = string
            cpu    = string
          })
        })
      })
    })
    ingress = object({
      enabled     = bool
      className   = string
      annotations = map(string)
      hosts = list(object({
        host = string
        paths = list(object({
          path     = string
          pathType = string
        }))
      }))
      tls = list(object({
        secretName = string
        hosts      = list(string)
      }))
    })
    resources = object({
      backend = object({
        requests = object({
          memory = string
          cpu    = string
        })
        limits = object({
          memory = string
          cpu    = string
        })
      })
      frontend = object({
        requests = object({
          memory = string
          cpu    = string
        })
        limits = object({
          memory = string
          cpu    = string
        })
      })
    })
  })
}

variable "namespace" {
  description = "Kubernetes namespace for Backstage"
  type        = string
  default     = "backstage"
}

variable "kubeconfig_path" {
  description = "Path to kubeconfig file for Kubernetes provider"
  type        = string
  default     = null
}

# GitHub integration credentials
variable "github_client_id" {
  description = "GitHub OAuth Client ID for Backstage authentication"
  type        = string
  sensitive   = true
  default     = ""
}

variable "github_client_secret" {
  description = "GitHub OAuth Client Secret for Backstage authentication"
  type        = string
  sensitive   = true
  default     = ""
}

variable "github_token" {
  description = "GitHub Personal Access Token for repository integration"
  type        = string
  sensitive   = true
  default     = ""
}

# External database configuration (for Aurora Serverless future migration)
variable "external_postgres_host" {
  description = "External PostgreSQL host (e.g., Aurora Serverless endpoint)"
  type        = string
  default     = ""
}

variable "external_postgres_port" {
  description = "External PostgreSQL port"
  type        = number
  default     = 5432
}

variable "external_postgres_database" {
  description = "External PostgreSQL database name"
  type        = string
  default     = "backstage"
}

variable "external_postgres_user" {
  description = "External PostgreSQL username"
  type        = string
  default     = "backstage"
  sensitive   = true
}

variable "external_postgres_password" {
  description = "External PostgreSQL password"
  type        = string
  default     = ""
  sensitive   = true
}

# Resource tags following MSDP conventions
variable "tags" {
  description = "Tags to apply to all resources"
  type        = map(string)
  default = {
    Environment = "dev"
    Project     = "msdp"
    Component   = "platform-engineering"
    ManagedBy   = "terraform"
    Owner       = "platform-team"
  }
}
