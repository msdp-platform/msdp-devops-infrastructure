# Cert-Manager Terraform Module
# This module manages Cert-Manager using Terraform + Helm Provider

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

# Create namespace
resource "kubernetes_namespace" "cert_manager" {
  count = var.enabled ? 1 : 0

  metadata {
    name = var.namespace

    labels = {
      "app.kubernetes.io/name"             = "cert-manager"
      "app.kubernetes.io/managed-by"       = "terraform"
      "app.kubernetes.io/part-of"          = "kubernetes-addons"
      "cert-manager.io/disable-validation" = "true"
    }
  }
}

# Install CRDs first
resource "helm_release" "cert_manager_crds" {
  count = var.enabled ? 1 : 0

  name       = "cert-manager-crds"
  repository = "https://charts.jetstack.io"
  chart      = "cert-manager"
  version    = var.chart_version
  namespace  = "kube-system"

  values = [
    yamlencode({
      installCRDs = true
    })
  ]

  # Install only the CRDs
  set {
    name  = "installCRDs"
    value = "true"
  }

  # Disable all components except CRDs
  set {
    name  = "extraArgs"
    value = "{}"
  }

  wait              = true
  wait_for_jobs     = true
  timeout           = var.installation_timeout
  cleanup_on_fail   = true
  atomic            = true
  dependency_update = false
}

# Create AWS credentials secret for cross-cloud access (Azure clusters)
resource "kubernetes_secret" "aws_credentials" {
  count = var.enabled && var.cloud_provider == "azure" ? 1 : 0

  metadata {
    name      = "aws-credentials"
    namespace = kubernetes_namespace.cert_manager[0].metadata[0].name
  }

  data = {
    aws-access-key-id     = var.aws_access_key_id
    aws-secret-access-key = var.aws_secret_access_key
  }

  type = "Opaque"
}

# Create service account with appropriate annotations
resource "kubernetes_service_account" "cert_manager" {
  count = var.enabled ? 1 : 0

  metadata {
    name      = "cert-manager"
    namespace = kubernetes_namespace.cert_manager[0].metadata[0].name

    annotations = merge(
      var.cloud_provider == "aws" ? {
        "eks.amazonaws.com/role-arn" = var.aws_role_arn
      } : {},
      var.cloud_provider == "azure" && var.use_oidc ? {
        "azure.workload.identity/client-id" = var.azure_workload_identity_client_id
      } : {}
    )

    labels = {
      "app.kubernetes.io/name"       = "cert-manager"
      "app.kubernetes.io/managed-by" = "terraform"
    }
  }

  automount_service_account_token = true
}

# Deploy Cert-Manager using Helm
locals {
  base_cert_manager_values = var.enabled ? [
    templatefile("${path.module}/values.yaml", {
      email                             = var.email
      log_level                         = var.log_level
      dns_challenge                     = var.dns_challenge
      dns_provider                      = var.dns_provider
      aws_region                        = var.aws_region
      hosted_zone_id                    = var.hosted_zone_id
      service_account_name              = kubernetes_service_account.cert_manager[0].metadata[0].name
      resources                         = jsonencode(var.resources)
      security_context                  = jsonencode(var.security_context)
      use_aws_credentials               = var.cloud_provider == "azure" && !var.use_oidc
      aws_credentials_secret            = var.cloud_provider == "azure" && !var.use_oidc && length(kubernetes_secret.aws_credentials) > 0 ? kubernetes_secret.aws_credentials[0].metadata[0].name : ""
      metrics_enabled                   = var.metrics_enabled
      prometheus_servicemonitor_enabled = var.prometheus_servicemonitor_enabled
      webhook_resources                 = jsonencode(var.webhook_resources)
      cainjector_resources              = jsonencode(var.cainjector_resources)
    })
  ] : []

  acme_server_url = var.cluster_issuer_name == "letsencrypt-prod" ? "https://acme-v02.api.letsencrypt.org/directory" : "https://acme-staging-v02.api.letsencrypt.org/directory"

  cluster_issuer_dns_solvers = var.dns_provider == "route53" ? [
    {
      dns01 = {
        route53 = {
          region       = var.aws_region
          hostedZoneID = var.hosted_zone_id
        }
      }
      http01 = null
    }
    ] : [
    {
      dns01 = {
        azureDNS = {
          subscriptionID    = var.azure_subscription_id
          resourceGroupName = var.azure_resource_group
          hostedZoneName    = var.azure_hosted_zone_name
        }
      }
      http01 = null
    }
  ]

  cluster_issuer_http_solver = [
    {
      dns01 = null
      http01 = {
        ingress = {
          ingressClassName = var.ingress_class_name
          ingressTemplate = {
            metadata = {}
          }
        }
      }
    }
  ]

  cluster_issuer_solvers = var.dns_challenge ? local.cluster_issuer_dns_solvers : local.cluster_issuer_http_solver

  cluster_issuer_manifest = var.create_cluster_issuer ? {
    apiVersion = "cert-manager.io/v1"
    kind       = "ClusterIssuer"
    metadata = {
      name = var.cluster_issuer_name
      labels = {
        "app.kubernetes.io/name"       = "cert-manager"
        "app.kubernetes.io/managed-by" = "terraform"
      }
    }
    spec = {
      acme = {
        server = local.acme_server_url
        email  = var.email
        privateKeySecretRef = {
          name = "${var.cluster_issuer_name}-private-key"
        }
        solvers = local.cluster_issuer_solvers
      }
    }
  } : null

  cluster_issuer_extra_values = var.create_cluster_issuer ? yamlencode({
    extraDeploy = [yamlencode(local.cluster_issuer_manifest)]
  }) : null

  cert_manager_values = compact(concat(local.base_cert_manager_values, [local.cluster_issuer_extra_values]))
}

resource "helm_release" "cert_manager" {
  count = var.enabled ? 1 : 0

  name       = "cert-manager"
  repository = "https://charts.jetstack.io"
  chart      = "cert-manager"
  version    = var.chart_version
  namespace  = kubernetes_namespace.cert_manager[0].metadata[0].name

  # Wait for namespace, service account, and CRDs
  depends_on = [
    kubernetes_namespace.cert_manager,
    kubernetes_service_account.cert_manager,
    kubernetes_secret.aws_credentials,
    helm_release.cert_manager_crds
  ]

  values = local.cert_manager_values

  # Timeout and retry configuration
  timeout         = var.installation_timeout
  wait            = true
  wait_for_jobs   = true
  atomic          = var.atomic_installation
  cleanup_on_fail = true

  # Force update if values change
  recreate_pods = true
}

# Output important information
output "namespace" {
  description = "The namespace where Cert-Manager is deployed"
  value       = var.enabled ? kubernetes_namespace.cert_manager[0].metadata[0].name : null
}

output "service_account" {
  description = "The service account used by Cert-Manager"
  value       = var.enabled ? kubernetes_service_account.cert_manager[0].metadata[0].name : null
}

output "helm_release_status" {
  description = "The status of the Helm release"
  value       = var.enabled ? helm_release.cert_manager[0].status : null
}

output "helm_release_version" {
  description = "The version of the deployed Helm chart"
  value       = var.enabled ? helm_release.cert_manager[0].version : null
}

output "cluster_issuer_name" {
  description = "The name of the created ClusterIssuer"
  value       = var.enabled && var.create_cluster_issuer ? var.cluster_issuer_name : null
}
