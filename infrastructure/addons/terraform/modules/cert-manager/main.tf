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
      "app.kubernetes.io/name"       = "cert-manager"
      "app.kubernetes.io/managed-by" = "terraform"
      "app.kubernetes.io/part-of"    = "kubernetes-addons"
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
    
    annotations = var.cloud_provider == "aws" ? {
      "eks.amazonaws.com/role-arn" = var.aws_role_arn
    } : {}
    
    labels = {
      "app.kubernetes.io/name"       = "cert-manager"
      "app.kubernetes.io/managed-by" = "terraform"
    }
  }
  
  automount_service_account_token = true
}

# Deploy Cert-Manager using Helm
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
  
  values = [
    templatefile("${path.module}/values.yaml", {
      # Common configuration
      email            = var.email
      log_level        = var.log_level
      
      # DNS challenge configuration
      dns_challenge    = var.dns_challenge
      dns_provider     = var.dns_provider
      aws_region       = var.aws_region
      hosted_zone_id   = var.hosted_zone_id
      
      # Service account
      service_account_name = kubernetes_service_account.cert_manager[0].metadata[0].name
      
      # Resource configuration
      resources        = jsonencode(var.resources)
      
      # Security configuration
      security_context = jsonencode(var.security_context)
      
      # AWS credentials (for Azure clusters)
      use_aws_credentials = var.cloud_provider == "azure" && !var.use_oidc
      aws_credentials_secret = var.cloud_provider == "azure" && !var.use_oidc && length(kubernetes_secret.aws_credentials) > 0 ? kubernetes_secret.aws_credentials[0].metadata[0].name : ""
      
      # Monitoring configuration
      metrics_enabled = var.metrics_enabled
      prometheus_servicemonitor_enabled = var.prometheus_servicemonitor_enabled
      
      # Webhook configuration
      webhook_resources = jsonencode(var.webhook_resources)
      cainjector_resources = jsonencode(var.cainjector_resources)
    })
  ]
  
  # Timeout and retry configuration
  timeout          = var.installation_timeout
  wait             = true
  wait_for_jobs    = true
  atomic           = var.atomic_installation
  cleanup_on_fail  = true
  
  # Force update if values change
  recreate_pods = true
}

# Create ClusterIssuer for Let's Encrypt
resource "kubernetes_manifest" "cluster_issuer" {
  count = var.enabled && var.create_cluster_issuer ? 1 : 0
  
  manifest = {
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
        server = var.cluster_issuer_name == "letsencrypt-prod" ? "https://acme-v02.api.letsencrypt.org/directory" : "https://acme-staging-v02.api.letsencrypt.org/directory"
        email = var.email
       privateKeySecretRef = {
         name = "${var.cluster_issuer_name}-private-key"
       }
        solvers = [
          var.dns_challenge ? {
            dns01 = var.dns_provider == "route53" ? {
              route53 = {
                region = var.aws_region
                hostedZoneID = var.hosted_zone_id
              }
            } : {
              azureDNS = {
                subscriptionID    = var.azure_subscription_id
                resourceGroupName = var.azure_resource_group
                hostedZoneName    = var.azure_hosted_zone_name
              }
            }
          } : {
            http01 = {
              ingress = {
                class            = var.ingress_class_name
                ingressClassName = var.ingress_class_name
                ingressTemplate  = {
                  metadata = {}
                }
              }
            }
          }
        ]
      }
    }
  }
  
  depends_on = [helm_release.cert_manager]
  
  wait {
    condition {
      type   = "Ready"
      status = "True"
    }
  }
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
