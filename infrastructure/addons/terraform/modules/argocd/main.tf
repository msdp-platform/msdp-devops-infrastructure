# ArgoCD Terraform Module
# This module manages ArgoCD using Terraform + Helm Provider

terraform {
  required_providers {
    helm = {
      source  = "hashicorp/helm"
      version = "~> 2.15"
    }
    kubernetes = {
      source  = "hashicorp/kubernetes"
      version = "~> 2.24"
    }
  }
}

# Import shared versions
module "versions" {
  source = "../shared/versions"
}

resource "kubernetes_namespace" "argocd" {
  count = var.enabled ? 1 : 0

  metadata {
    name = var.namespace
    labels = {
      "app.kubernetes.io/name"       = "argocd"
      "app.kubernetes.io/managed-by" = "terraform"
    }
  }
}

locals {
  ingress_annotations = merge(
    var.cluster_issuer_name != "" ? {
      "cert-manager.io/cluster-issuer" = var.cluster_issuer_name
    } : {},
    var.ingress_annotations
  )
}

resource "helm_release" "argocd" {
  count = var.enabled ? 1 : 0

  name       = "argocd"
  repository = "https://argoproj.github.io/argo-helm"
  chart      = "argo-cd"
  version    = module.versions.chart_versions.argocd
  namespace  = kubernetes_namespace.argocd[0].metadata[0].name

  values = [
    templatefile("${path.module}/values.yaml", {
      hostname            = var.hostname
      ingress_class_name  = var.ingress_class_name
      tls_secret_name     = var.tls_secret_name
      ingress_annotations = local.ingress_annotations
      server_extra_args   = var.server_extra_args
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
  description = "Namespace where Argo CD is deployed"
  value       = var.enabled ? kubernetes_namespace.argocd[0].metadata[0].name : null
}

output "helm_release_status" {
  description = "Status of the Argo CD Helm release"
  value       = var.enabled ? helm_release.argocd[0].status : null
}

output "helm_release_version" {
  description = "Version of the deployed Helm chart"
  value       = var.enabled ? helm_release.argocd[0].version : null
}

output "hostname" {
  description = "Argo CD ingress hostname"
  value       = var.enabled ? var.hostname : null
}
