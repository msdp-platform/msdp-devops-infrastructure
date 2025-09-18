# Prometheus Stack Terraform Module

terraform {
  required_providers {
    helm = {
      source  = "hashicorp/helm"
      version = "~> 2.12"
    }
    kubernetes = {
      source  = "hashicorp/kubernetes"
      version = "~> 2.24"
    }
  }
}

resource "kubernetes_namespace" "prometheus" {
  count = var.enabled ? 1 : 0

  metadata {
    name = var.namespace
    labels = {
      "app.kubernetes.io/name"       = "prometheus-stack"
      "app.kubernetes.io/managed-by" = "terraform"
    }
  }
}

locals {
  prometheus_annotations = merge(
    var.cluster_issuer_name != "" ? {
      "cert-manager.io/cluster-issuer" = var.cluster_issuer_name
    } : {},
    var.prometheus_additional_annotations
  )

  grafana_annotations = merge(
    var.cluster_issuer_name != "" ? {
      "cert-manager.io/cluster-issuer" = var.cluster_issuer_name
    } : {},
    var.grafana_additional_annotations
  )
}

resource "helm_release" "prometheus_stack" {
  count = var.enabled ? 1 : 0

  name       = "kube-prometheus-stack"
  repository = "https://prometheus-community.github.io/helm-charts"
  chart      = "kube-prometheus-stack"
  version    = var.chart_version
  namespace  = kubernetes_namespace.prometheus[0].metadata[0].name

  values = [
    templatefile("${path.module}/values.yaml", {
      prometheus_hostname      = var.prometheus_hostname
      grafana_hostname         = var.grafana_hostname
      ingress_class_name       = var.ingress_class_name
      prometheus_tls_secret    = var.prometheus_tls_secret_name
      grafana_tls_secret       = var.grafana_tls_secret_name
      prometheus_annotations   = indent(6, yamlencode(local.prometheus_annotations))
      grafana_annotations      = indent(6, yamlencode(local.grafana_annotations))
    })
  ]

  timeout          = var.installation_timeout
  wait             = true
  wait_for_jobs    = true
  atomic           = true
  cleanup_on_fail  = true
  dependency_update = false
}

output "namespace" {
  description = "Namespace where Prometheus stack is deployed"
  value       = var.enabled ? kubernetes_namespace.prometheus[0].metadata[0].name : null
}

output "helm_release_status" {
  description = "Status of the Helm release"
  value       = var.enabled ? helm_release.prometheus_stack[0].status : null
}

output "helm_release_version" {
  description = "Version of the deployed Helm chart"
  value       = var.enabled ? helm_release.prometheus_stack[0].version : null
}

output "prometheus_hostname" {
  description = "Prometheus ingress hostname"
  value       = var.enabled ? var.prometheus_hostname : null
}

output "grafana_hostname" {
  description = "Grafana ingress hostname"
  value       = var.enabled ? var.grafana_hostname : null
}
