# Cert-Manager Terraform Module Variables

variable "enabled" {
  description = "Enable or disable Cert-Manager deployment"
  type        = bool
  default     = true
}

variable "namespace" {
  description = "Kubernetes namespace for Cert-Manager"
  type        = string
  default     = "cert-manager"
}

variable "chart_version" {
  description = "Version of the Cert-Manager Helm chart"
  type        = string
  default     = "v1.13.2"
}

variable "crds_version" {
  description = "Version of the Cert-Manager CRDs to install"
  type        = string
  default     = "v1.13.2"
}

# Certificate Configuration
variable "email" {
  description = "Email address for Let's Encrypt registration"
  type        = string
}

variable "create_cluster_issuer" {
  description = "Create a ClusterIssuer for Let's Encrypt"
  type        = bool
  default     = true
}

variable "cluster_issuer_name" {
  description = "Name of the ClusterIssuer to create"
  type        = string
  default     = "letsencrypt-prod"
  
  validation {
    condition     = contains(["letsencrypt-prod", "letsencrypt-prod"], var.cluster_issuer_name)
    error_message = "Cluster issuer name must be either 'letsencrypt-prod'."
  }
}

variable "cluster_issuer" {
  description = "Cluster issuer name (alias for cluster_issuer_name for compatibility)"
  type        = string
  default     = ""
}

# DNS Challenge Configuration
variable "dns_challenge" {
  description = "Enable DNS-01 challenge"
  type        = bool
  default     = true
}

variable "dns_provider" {
  description = "DNS provider for DNS-01 challenge"
  type        = string
  default     = "route53"
  
  validation {
    condition     = contains(["route53", "azuredns", "cloudflare"], var.dns_provider)
    error_message = "DNS provider must be one of: route53, azuredns, cloudflare."
  }
}

variable "ingress_class_name" {
  description = "Ingress class name used for HTTP01 solver"
  type        = string
  default     = "nginx"
}

# AWS Configuration
variable "aws_region" {
  description = "AWS region for Route53"
  type        = string
  default     = "eu-west-1"
}

variable "hosted_zone_id" {
  description = "AWS Route53 hosted zone ID"
  type        = string
  default     = "Z0581458B5QGVNLDPESN"
}

variable "aws_role_arn" {
  description = "AWS IAM role ARN for service account (EKS)"
  type        = string
  default     = ""
}

variable "aws_access_key_id" {
  description = "AWS access key ID (for Azure clusters)"
  type        = string
  default     = ""
  sensitive   = true
}

variable "aws_secret_access_key" {
  description = "AWS secret access key (for Azure clusters)"
  type        = string
  default     = ""
  sensitive   = true
}

variable "aws_web_identity_token_file" {
  description = "Path to the web identity token file for OIDC authentication"
  type        = string
  default     = "/var/run/secrets/eks.amazonaws.com/serviceaccount/token"
}

variable "use_oidc" {
  description = "Use OIDC authentication instead of static credentials"
  type        = bool
  default     = false
}

# Azure Configuration
variable "azure_subscription_id" {
  description = "Azure subscription ID"
  type        = string
  default     = ""
}

variable "azure_resource_group" {
  description = "Azure resource group for DNS zone"
  type        = string
  default     = ""
}

variable "azure_hosted_zone_name" {
  description = "Azure DNS hosted zone name"
  type        = string
  default     = ""
}

# Cloud Provider Configuration
variable "cloud_provider" {
  description = "Cloud provider (aws or azure)"
  type        = string
  
  validation {
    condition     = contains(["aws", "azure"], var.cloud_provider)
    error_message = "Cloud provider must be either 'aws' or 'azure'."
  }
}

# Application Configuration
variable "log_level" {
  description = "Log level for Cert-Manager"
  type        = string
  default     = "2"
  
  validation {
    condition     = contains(["1", "2", "3", "4", "5"], var.log_level)
    error_message = "Log level must be between 1 and 5."
  }
}

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
      cpu    = "100m"
      memory = "128Mi"
    }
    limits = {
      cpu    = "500m"
      memory = "512Mi"
    }
  }
}

variable "webhook_resources" {
  description = "Resource requests and limits for webhook"
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

variable "cainjector_resources" {
  description = "Resource requests and limits for cainjector"
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
  description = "Security context for Cert-Manager pods"
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
    runAsUser                = 1000
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

variable "prometheus_servicemonitor_enabled" {
  description = "Enable Prometheus ServiceMonitor"
  type        = bool
  default     = false
}

# Node Selection
variable "node_selector" {
  description = "Node selector for Cert-Manager pods"
  type        = map(string)
  default     = {}
}

variable "tolerations" {
  description = "Tolerations for Cert-Manager pods"
  type = list(object({
    key      = string
    operator = string
    value    = string
    effect   = string
  }))
  default = []
}

variable "affinity" {
  description = "Affinity rules for Cert-Manager pods"
  type        = any
  default     = {}
}
