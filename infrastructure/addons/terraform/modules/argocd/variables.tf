# Argo CD Module Variables

variable "enabled" {
  description = "Enable or disable Argo CD deployment"
  type        = bool
  default     = true
}

variable "namespace" {
  description = "Kubernetes namespace for Argo CD"
  type        = string
  default     = "argocd"
}

variable "chart_version" {
  description = "Helm chart version for argo-cd"
  type        = string
  default     = "5.51.3"
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
  description = "Hostname used to expose the Argo CD UI"
  type        = string
}

variable "tls_secret_name" {
  description = "TLS secret name for the Argo CD ingress"
  type        = string
  default     = "argocd-tls"
}

variable "additional_ingress_annotations" {
  description = "Additional ingress annotations"
  type        = map(string)
  default     = {}
}

variable "server_extra_args" {
  description = "Additional arguments for the Argo CD server"
  type        = list(string)
  default     = ["--insecure"]
}

variable "installation_timeout" {
  description = "Helm installation timeout in seconds"
  type        = number
  default     = 600
}
