# Crossplane 2.x Terraform Module for MSDP Platform Engineering

terraform {
  required_version = ">= 1.9"
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

# Provider configurations - explicitly use kubeconfig
provider "kubernetes" {
  config_path = var.kubeconfig_path
}

provider "helm" {
  kubernetes {
    config_path = var.kubeconfig_path
  }
}

provider "kubectl" {
  config_path = var.kubeconfig_path
}

# Load configuration from tfvars
locals {
  component_config = var.component_config
  namespace        = var.namespace
  chart_version    = var.component_config.chart_version

  # MSDP-specific labels following your conventions
  common_labels = {
    "app.kubernetes.io/name"       = "crossplane"
    "app.kubernetes.io/instance"   = "msdp-crossplane"
    "app.kubernetes.io/version"    = local.chart_version
    "app.kubernetes.io/component"  = "infrastructure-engine"
    "app.kubernetes.io/part-of"    = "msdp-platform-engineering"
    "app.kubernetes.io/managed-by" = "terraform"
    "msdp.platform/component"      = "crossplane"
    "msdp.platform/environment"    = var.environment
  }

  # Provider configurations
  azure_provider_config = var.component_config.providers.azure
  aws_provider_config   = var.component_config.providers.aws
  k8s_provider_config   = var.component_config.providers.kubernetes
}

# Crossplane namespace
resource "kubernetes_namespace" "crossplane_system" {
  metadata {
    name   = local.namespace
    labels = local.common_labels
  }
}

# Azure credentials secret for Crossplane
resource "kubernetes_secret" "azure_credentials" {
  count = local.azure_provider_config.enabled ? 1 : 0

  metadata {
    name      = "azure-secret"
    namespace = kubernetes_namespace.crossplane_system.metadata[0].name
    labels    = local.common_labels
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

# AWS credentials secret for Crossplane
resource "kubernetes_secret" "aws_credentials" {
  count = local.aws_provider_config.enabled ? 1 : 0

  metadata {
    name      = "aws-secret"
    namespace = kubernetes_namespace.crossplane_system.metadata[0].name
    labels    = local.common_labels
  }

  data = {
    creds = jsonencode({
      accessKeyId     = var.aws_access_key_id
      secretAccessKey = var.aws_secret_access_key
      region          = var.aws_region
    })
  }

  type = "Opaque"
}

# Crossplane Helm release
resource "helm_release" "crossplane" {
  name       = "crossplane"
  repository = local.component_config.repository
  chart      = "crossplane"
  version    = local.chart_version
  namespace  = kubernetes_namespace.crossplane_system.metadata[0].name

  # Crossplane 2.x values
  values = [
    yamlencode({
      # Core Crossplane configuration
      configuration = {
        packages = local.component_config.values.configuration.packages
      }

      # Resource limits following your patterns
      resourcesCrossplane = local.component_config.values.resourcesCrossplane

      # RBAC manager configuration
      rbacManager = local.component_config.values.rbacManager

      # Package manager for provider installation
      packageManager = local.component_config.values.packageManager

      # Additional configuration for Crossplane 2.x
      args = [
        "--enable-usages",
        "--enable-realtime-compositions"
      ]

      # Metrics and monitoring
      metrics = {
        enabled = true
      }

      # Security context
      securityContext = {
        runAsNonRoot = true
        runAsUser    = 65532
        runAsGroup   = 65532
      }

      # Node selector for system nodes (following your AKS patterns)
      nodeSelector = {
        "kubernetes.io/os" = "linux"
      }

      # Tolerations for system workloads
      tolerations = [
        {
          key      = "CriticalAddonsOnly"
          operator = "Exists"
        }
      ]
    })
  ]

  timeout         = 600
  wait            = true
  wait_for_jobs   = true
  atomic          = true
  cleanup_on_fail = true

  depends_on = [
    kubernetes_namespace.crossplane_system
  ]
}

# Azure Provider Configuration
resource "kubectl_manifest" "azure_provider_config" {
  count = local.azure_provider_config.enabled ? 1 : 0

  yaml_body = yamlencode({
    apiVersion = "pkg.crossplane.io/v1"
    kind       = "Provider"
    metadata = {
      name   = "provider-azure"
      labels = local.common_labels
    }
    spec = {
      package                  = "xpkg.upbound.io/crossplane-contrib/provider-azure:${local.azure_provider_config.version}"
      revisionActivationPolicy = "Automatic"
      revisionHistoryLimit     = 3
    }
  })

  depends_on = [helm_release.crossplane]
}

# AWS Provider Configuration  
resource "kubectl_manifest" "aws_provider_config" {
  count = local.aws_provider_config.enabled ? 1 : 0

  yaml_body = yamlencode({
    apiVersion = "pkg.crossplane.io/v1"
    kind       = "Provider"
    metadata = {
      name   = "provider-aws"
      labels = local.common_labels
    }
    spec = {
      package                  = "xpkg.upbound.io/crossplane-contrib/provider-aws:${local.aws_provider_config.version}"
      revisionActivationPolicy = "Automatic"
      revisionHistoryLimit     = 3
    }
  })

  depends_on = [helm_release.crossplane]
}

# Kubernetes Provider Configuration
resource "kubectl_manifest" "kubernetes_provider_config" {
  count = local.k8s_provider_config.enabled ? 1 : 0

  yaml_body = yamlencode({
    apiVersion = "pkg.crossplane.io/v1"
    kind       = "Provider"
    metadata = {
      name   = "provider-kubernetes"
      labels = local.common_labels
    }
    spec = {
      package                  = "xpkg.upbound.io/crossplane-contrib/provider-kubernetes:${local.k8s_provider_config.version}"
      revisionActivationPolicy = "Automatic"
      revisionHistoryLimit     = 3
    }
  })

  depends_on = [helm_release.crossplane]
}

# Wait for providers to be ready
resource "time_sleep" "wait_for_providers" {
  depends_on = [
    kubectl_manifest.azure_provider_config,
    kubectl_manifest.aws_provider_config,
    kubectl_manifest.kubernetes_provider_config
  ]

  create_duration = "60s"
}

# Azure Provider Config (credentials)
resource "kubectl_manifest" "azure_provider_credentials" {
  count = local.azure_provider_config.enabled ? 1 : 0

  yaml_body = yamlencode({
    apiVersion = "azure.crossplane.io/v1beta1"
    kind       = "ProviderConfig"
    metadata = {
      name   = "default"
      labels = local.common_labels
    }
    spec = {
      credentials = {
        source = "Secret"
        secretRef = {
          namespace = kubernetes_namespace.crossplane_system.metadata[0].name
          name      = kubernetes_secret.azure_credentials[0].metadata[0].name
          key       = "creds"
        }
      }
    }
  })

  depends_on = [time_sleep.wait_for_providers]
}

# AWS Provider Config (credentials)
resource "kubectl_manifest" "aws_provider_credentials" {
  count = local.aws_provider_config.enabled ? 1 : 0

  yaml_body = yamlencode({
    apiVersion = "aws.crossplane.io/v1beta1"
    kind       = "ProviderConfig"
    metadata = {
      name   = "default"
      labels = local.common_labels
    }
    spec = {
      credentials = {
        source = "Secret"
        secretRef = {
          namespace = kubernetes_namespace.crossplane_system.metadata[0].name
          name      = kubernetes_secret.aws_credentials[0].metadata[0].name
          key       = "creds"
        }
      }
    }
  })

  depends_on = [time_sleep.wait_for_providers]
}

# Note: Aurora Serverless Composition removed for initial deployment
# Will be added back with proper Crossplane v2.x Pipeline format later

# Outputs following your convention
output "crossplane_namespace" {
  description = "Crossplane system namespace"
  value       = kubernetes_namespace.crossplane_system.metadata[0].name
}

output "crossplane_version" {
  description = "Deployed Crossplane version"
  value       = helm_release.crossplane.version
}

output "providers_enabled" {
  description = "Enabled Crossplane providers"
  value = {
    azure      = local.azure_provider_config.enabled
    aws        = local.aws_provider_config.enabled
    kubernetes = local.k8s_provider_config.enabled
  }
}

output "helm_release_status" {
  description = "Crossplane Helm release status"
  value       = helm_release.crossplane.status
}
