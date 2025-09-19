# Backstage Module Variables

variable "enabled" {
  description = "Enable or disable Backstage deployment"
  type        = bool
  default     = true
}

variable "namespace" {
  description = "Kubernetes namespace for Backstage"
  type        = string
  default     = "backstage"
}


variable "backstage_version" {
  description = "Backstage application version"
  type        = string
  default     = "v1.43.1"
}

variable "cluster_issuer_name" {
  description = "Cert-Manager cluster issuer for TLS"
  type        = string
  default     = ""
}

variable "ingress_class_name" {
  description = "Ingress class name used by NGINX"
  type        = string
  default     = "nginx"
}

variable "hostname" {
  description = "Hostname for Backstage ingress"
  type        = string
  default     = "backstage.example.com"
}

variable "tls_secret_name" {
  description = "Name of the TLS secret for ingress"
  type        = string
  default     = "backstage-tls"
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
