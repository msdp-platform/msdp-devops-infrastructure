# Crossplane Terraform Module
# This module manages Crossplane using Terraform + Helm Provider

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
    kubectl = {
      source  = "gavinbunney/kubectl"
      version = "~> 1.14"
    }
  }
}

resource "kubernetes_namespace" "crossplane_system" {
  count = var.enabled ? 1 : 0

  metadata {
    name = var.namespace
    labels = {
      "app.kubernetes.io/name"       = "crossplane"
      "app.kubernetes.io/managed-by" = "terraform"
    }
  }
}

resource "helm_release" "crossplane" {
  count = var.enabled ? 1 : 0

  name       = "crossplane"
  repository = "https://charts.crossplane.io/stable"
  chart      = "crossplane"
  version    = module.versions.chart_versions.crossplane
  namespace  = kubernetes_namespace.crossplane_system[0].metadata[0].name

  values = [
    templatefile("${path.module}/values.yaml", {
      crossplane_version = var.crossplane_version
      azure_enabled      = var.crossplane_providers.azure.enabled
      aws_enabled        = var.crossplane_providers.aws.enabled
      kubernetes_enabled = var.crossplane_providers.kubernetes.enabled
    })
  ]

  timeout         = var.installation_timeout
  wait            = true
  wait_for_jobs   = true
  atomic          = true
  cleanup_on_fail = true

  depends_on = [kubernetes_namespace.crossplane_system]
}

# Azure credentials secret
resource "kubernetes_secret" "azure_credentials" {
  count = var.enabled && var.crossplane_providers.azure.enabled ? 1 : 0

  metadata {
    name      = "azure-secret"
    namespace = kubernetes_namespace.crossplane_system[0].metadata[0].name
  }

  data = {
    creds = jsonencode({
      clientId       = var.azure_client_id
      clientSecret   = var.azure_client_secret
      tenantId       = var.azure_tenant_id
      subscriptionId = var.azure_subscription_id
    })
  }

  type = "Opaque"
}

# Use shared AWS credentials module
module "aws_credentials" {
  source = "../shared/aws-credentials"
  count  = var.enabled && var.crossplane_providers.aws.enabled ? 1 : 0

  enabled               = true
  secret_name          = "aws-secret"
  namespace            = kubernetes_namespace.crossplane_system[0].metadata[0].name
  aws_access_key_id    = var.aws_access_key_id
  aws_secret_access_key = var.aws_secret_access_key
  aws_region           = var.aws_region
  secret_format        = "crossplane"
  
  labels = {
    "app.kubernetes.io/name"       = "crossplane"
    "app.kubernetes.io/component"  = "aws-credentials"
  }
}

# Wait for Crossplane to be ready
resource "time_sleep" "wait_for_crossplane" {
  count = var.enabled ? 1 : 0

  depends_on = [helm_release.crossplane]

  create_duration = "60s"
}

# Azure Provider Installation
resource "kubectl_manifest" "azure_provider" {
  count = var.enabled && var.crossplane_providers.azure.enabled ? 1 : 0

  yaml_body = yamlencode({
    apiVersion = "pkg.crossplane.io/v1"
    kind       = "Provider"
    metadata = {
      name = "provider-azure"
    }
    spec = {
      package = "xpkg.upbound.io/crossplane-contrib/provider-azure:${var.crossplane_providers.azure.version}"
    }
  })

  depends_on = [time_sleep.wait_for_crossplane]
}

# AWS Provider Installation
resource "kubectl_manifest" "aws_provider" {
  count = var.enabled && var.crossplane_providers.aws.enabled ? 1 : 0

  yaml_body = yamlencode({
    apiVersion = "pkg.crossplane.io/v1"
    kind       = "Provider"
    metadata = {
      name = "provider-aws"
    }
    spec = {
      package = "xpkg.upbound.io/crossplane-contrib/provider-aws:${var.crossplane_providers.aws.version}"
    }
  })

  depends_on = [time_sleep.wait_for_crossplane]
}

# Kubernetes Provider Installation
resource "kubectl_manifest" "kubernetes_provider" {
  count = var.enabled && var.crossplane_providers.kubernetes.enabled ? 1 : 0

  yaml_body = yamlencode({
    apiVersion = "pkg.crossplane.io/v1"
    kind       = "Provider"
    metadata = {
      name = "provider-kubernetes"
    }
    spec = {
      package = "xpkg.upbound.io/crossplane-contrib/provider-kubernetes:${var.crossplane_providers.kubernetes.version}"
    }
  })

  depends_on = [time_sleep.wait_for_crossplane]
}

# Wait for providers to be ready
resource "time_sleep" "wait_for_providers" {
  count = var.enabled ? 1 : 0

  depends_on = [
    kubectl_manifest.azure_provider,
    kubectl_manifest.aws_provider,
    kubectl_manifest.kubernetes_provider
  ]

  create_duration = "120s"
}

# Azure Provider Config
resource "kubectl_manifest" "azure_provider_config" {
  count = var.enabled && var.crossplane_providers.azure.enabled ? 1 : 0

  yaml_body = yamlencode({
    apiVersion = "azure.crossplane.io/v1beta1"
    kind       = "ProviderConfig"
    metadata = {
      name = "default"
    }
    spec = {
      credentials = {
        source = "Secret"
        secretRef = {
          namespace = kubernetes_namespace.crossplane_system[0].metadata[0].name
          name      = kubernetes_secret.azure_credentials[0].metadata[0].name
          key       = "creds"
        }
      }
    }
  })

  depends_on = [time_sleep.wait_for_providers]
}

# AWS Provider Config
resource "kubectl_manifest" "aws_provider_config" {
  count = var.enabled && var.crossplane_providers.aws.enabled ? 1 : 0

  yaml_body = yamlencode({
    apiVersion = "aws.crossplane.io/v1beta1"
    kind       = "ProviderConfig"
    metadata = {
      name = "default"
    }
    spec = {
      credentials = {
        source = "Secret"
        secretRef = {
          namespace = kubernetes_namespace.crossplane_system[0].metadata[0].name
          name      = module.aws_credentials[0].secret_name
          key       = "creds"
        }
      }
    }
  })

  depends_on = [time_sleep.wait_for_providers]
}

# Kubernetes Provider Config
resource "kubectl_manifest" "kubernetes_provider_config" {
  count = var.enabled && var.crossplane_providers.kubernetes.enabled ? 1 : 0

  yaml_body = yamlencode({
    apiVersion = "kubernetes.crossplane.io/v1alpha1"
    kind       = "ProviderConfig"
    metadata = {
      name = "default"
    }
    spec = {
      credentials = {
        source = "InjectedIdentity"
      }
    }
  })

  depends_on = [time_sleep.wait_for_providers]
}

# Outputs
output "namespace" {
  description = "Namespace where Crossplane is deployed"
  value       = var.enabled ? kubernetes_namespace.crossplane_system[0].metadata[0].name : null
}

output "helm_release_status" {
  description = "Status of the Crossplane Helm release"
  value       = var.enabled ? helm_release.crossplane[0].status : null
}

output "helm_release_version" {
  description = "Version of the deployed Helm chart"
  value       = var.enabled ? helm_release.crossplane[0].version : null
}

output "crossplane_version" {
  description = "Crossplane application version"
  value       = var.enabled ? var.crossplane_version : null
}

output "providers_enabled" {
  description = "Enabled Crossplane providers"
  value = var.enabled ? {
    azure      = var.crossplane_providers.azure.enabled
    aws        = var.crossplane_providers.aws.enabled
    kubernetes = var.crossplane_providers.kubernetes.enabled
  } : null
}
