# Backstage Terraform Module
# This module manages Backstage using Terraform + Helm Provider

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

# Import shared versions
module "versions" {
  source = "../shared/versions"
}

resource "kubernetes_namespace" "backstage" {
  count = var.enabled ? 1 : 0

  metadata {
    name = var.namespace
    labels = {
      "app.kubernetes.io/name"       = "backstage"
      "app.kubernetes.io/managed-by" = "terraform"
    }
  }
}

locals {
  ingress_annotations = merge(
    var.cluster_issuer_name != "" ? {
      "cert-manager.io/cluster-issuer" = var.cluster_issuer_name
    } : {},
    var.additional_ingress_annotations
  )
}

resource "helm_release" "backstage" {
  count = var.enabled ? 1 : 0

  name       = "backstage"
  repository = "https://backstage.github.io/charts"
  chart      = "backstage"
  version    = module.versions.chart_versions.backstage
  namespace  = kubernetes_namespace.backstage[0].metadata[0].name

  values = [
    templatefile("${path.module}/values.yaml", {
      hostname               = var.hostname
      ingress_class_name     = var.ingress_class_name
      tls_secret_name        = var.tls_secret_name
      ingress_annotations    = local.ingress_annotations
      backstage_version      = var.backstage_version
      github_client_id       = var.github_client_id
      github_client_secret   = var.github_client_secret
      github_token           = var.github_token
      postgresql_enabled     = var.postgresql.enabled
      postgresql_username    = var.postgresql.auth.username
      postgresql_password    = var.postgresql.auth.password
      postgresql_database    = var.postgresql.auth.database
      external_postgres_host = var.external_postgres_host
      app_config_yaml        = yamlencode(var.app_config)
    })
  ]

  timeout         = var.installation_timeout
  wait            = true
  wait_for_jobs   = true
  atomic          = true
  cleanup_on_fail = true

  depends_on = [kubernetes_namespace.backstage]
}

# Outputs
output "namespace" {
  description = "Namespace where Backstage is deployed"
  value       = var.enabled ? kubernetes_namespace.backstage[0].metadata[0].name : null
}

output "helm_release_status" {
  description = "Status of the Backstage Helm release"
  value       = var.enabled ? helm_release.backstage[0].status : null
}

output "helm_release_version" {
  description = "Version of the deployed Helm chart"
  value       = var.enabled ? helm_release.backstage[0].version : null
}

output "hostname" {
  description = "Backstage ingress hostname"
  value       = var.enabled ? var.hostname : null
}

output "app_version" {
  description = "Backstage application version"
  value       = var.enabled ? var.backstage_version : null
}
