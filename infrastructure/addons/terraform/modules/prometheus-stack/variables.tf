# Prometheus Stack Module Variables

variable "enabled" {
  description = "Enable or disable the Prometheus stack deployment"
  type        = bool
  default     = true
}

variable "namespace" {
  description = "Kubernetes namespace for the Prometheus stack"
  type        = string
  default     = "monitoring"
}


variable "cluster_issuer_name" {
  description = "Cert-Manager cluster issuer used for TLS"
  type        = string
  default     = ""
}

variable "ingress_class_name" {
  description = "Ingress class name used by NGINX"
  type        = string
  default     = "nginx"
}

variable "prometheus_hostname" {
  description = "Hostname used to expose the Prometheus UI"
  type        = string

  validation {
    condition     = can(regex("^[a-zA-Z0-9]([a-zA-Z0-9\\-]{0,61}[a-zA-Z0-9])?(\\.[a-zA-Z0-9]([a-zA-Z0-9\\-]{0,61}[a-zA-Z0-9])?)*$", var.prometheus_hostname))
    error_message = "Prometheus hostname must be a valid DNS hostname format."
  }
}

variable "grafana_hostname" {
  description = "Hostname used to expose the Grafana UI"
  type        = string

  validation {
    condition     = can(regex("^[a-zA-Z0-9]([a-zA-Z0-9\\-]{0,61}[a-zA-Z0-9])?(\\.[a-zA-Z0-9]([a-zA-Z0-9\\-]{0,61}[a-zA-Z0-9])?)*$", var.grafana_hostname))
    error_message = "Grafana hostname must be a valid DNS hostname format."
  }
}

variable "prometheus_tls_secret_name" {
  description = "TLS secret name for Prometheus ingress"
  type        = string
  default     = "prometheus-tls"
}

variable "grafana_tls_secret_name" {
  description = "TLS secret name for Grafana ingress"
  type        = string
  default     = "grafana-tls"
}

variable "prometheus_additional_annotations" {
  description = "Additional annotations for the Prometheus ingress"
  type        = map(string)
  default     = {}
}

variable "grafana_additional_annotations" {
  description = "Additional annotations for the Grafana ingress"
  type        = map(string)
  default     = {}
}

variable "installation_timeout" {
  description = "Helm installation timeout in seconds"
  type        = number
  default     = 600
}
