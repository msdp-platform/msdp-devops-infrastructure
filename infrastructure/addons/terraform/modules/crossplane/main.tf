# Crossplane Terraform Module
# Follows MSDP addon patterns and integrates with existing infrastructure

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

# Crossplane system namespace
resource "kubernetes_namespace" "crossplane_system" {
  count = var.enabled ? 1 : 0

  metadata {
    name = var.namespace
    labels = {
      "app.kubernetes.io/name"       = "crossplane"
      "app.kubernetes.io/managed-by" = "terraform"
      "app.kubernetes.io/component"  = "infrastructure-engine"
      "app.kubernetes.io/part-of"    = "msdp-platform"
      "msdp.platform/component"      = "crossplane"
      "msdp.platform/environment"    = var.environment
    }
  }
}

# Azure credentials secret
resource "kubernetes_secret" "azure_credentials" {
  count = var.enabled && var.provider_configs.azure.enabled ? 1 : 0

  metadata {
    name      = "azure-secret"
    namespace = kubernetes_namespace.crossplane_system[0].metadata[0].name
    labels = {
      "app.kubernetes.io/name"      = "crossplane"
      "app.kubernetes.io/component" = "azure-credentials"
      "msdp.platform/component"     = "crossplane"
    }
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

# AWS credentials secret
resource "kubernetes_secret" "aws_credentials" {
  count = var.enabled && var.provider_configs.aws.enabled ? 1 : 0

  metadata {
    name      = "aws-secret"
    namespace = kubernetes_namespace.crossplane_system[0].metadata[0].name
    labels = {
      "app.kubernetes.io/name"      = "crossplane"
      "app.kubernetes.io/component" = "aws-credentials"
      "msdp.platform/component"     = "crossplane"
    }
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
  count = var.enabled ? 1 : 0

  name       = "crossplane"
  repository = "https://charts.crossplane.io/stable"
  chart      = "crossplane"
  version    = var.chart_version
  namespace  = kubernetes_namespace.crossplane_system[0].metadata[0].name

  values = [
    yamlencode({
      # Core Crossplane configuration
      args = [
        "--enable-composition-revisions",
        "--enable-environment-configs", 
        "--enable-usages"
      ]

      # Resource limits following your patterns
      resourcesCrossplane = var.resources

      # RBAC manager configuration
      rbacManager = {
        deploy = true
        resources = {
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

      # Package manager for provider installation
      packageManager = {
        deploy = true
        resources = {
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

      # Image configuration
      image = {
        repository = "crossplane/crossplane"
        tag        = var.crossplane_version
        pullPolicy = "IfNotPresent"
      }

      # Service account
      serviceAccount = {
        customAnnotations = {
          "app.kubernetes.io/managed-by" = "terraform"
        }
      }
    })
  ]

  timeout         = var.installation_timeout
  wait            = true
  wait_for_jobs   = true
  atomic          = true
  cleanup_on_fail = true

  depends_on = [kubernetes_namespace.crossplane_system]
}

# Azure Provider Installation
resource "kubectl_manifest" "azure_provider" {
  count = var.enabled && var.provider_configs.azure.enabled ? 1 : 0

  yaml_body = yamlencode({
    apiVersion = "pkg.crossplane.io/v1"
    kind       = "Provider"
    metadata = {
      name = "provider-azure"
      labels = {
        "app.kubernetes.io/managed-by" = "terraform"
        "msdp.platform/component"      = "crossplane"
        "msdp.platform/provider"       = "azure"
      }
    }
    spec = {
      package                  = "xpkg.upbound.io/crossplane-contrib/provider-azure:${var.provider_configs.azure.version}"
      revisionActivationPolicy = "Automatic"
      revisionHistoryLimit     = 3
    }
  })

  depends_on = [helm_release.crossplane]
}

# AWS Provider Installation
resource "kubectl_manifest" "aws_provider" {
  count = var.enabled && var.provider_configs.aws.enabled ? 1 : 0

  yaml_body = yamlencode({
    apiVersion = "pkg.crossplane.io/v1"
    kind       = "Provider"
    metadata = {
      name = "provider-aws"
      labels = {
        "app.kubernetes.io/managed-by" = "terraform"
        "msdp.platform/component"      = "crossplane"
        "msdp.platform/provider"       = "aws"
      }
    }
    spec = {
      package                  = "xpkg.upbound.io/crossplane-contrib/provider-aws:${var.provider_configs.aws.version}"
      revisionActivationPolicy = "Automatic"
      revisionHistoryLimit     = 3
    }
  })

  depends_on = [helm_release.crossplane]
}

# Kubernetes Provider Installation
resource "kubectl_manifest" "kubernetes_provider" {
  count = var.enabled && var.provider_configs.kubernetes.enabled ? 1 : 0

  yaml_body = yamlencode({
    apiVersion = "pkg.crossplane.io/v1"
    kind       = "Provider"
    metadata = {
      name = "provider-kubernetes"
      labels = {
        "app.kubernetes.io/managed-by" = "terraform"
        "msdp.platform/component"      = "crossplane"
        "msdp.platform/provider"       = "kubernetes"
      }
    }
    spec = {
      package                  = "xpkg.upbound.io/crossplane-contrib/provider-kubernetes:${var.provider_configs.kubernetes.version}"
      revisionActivationPolicy = "Automatic"
      revisionHistoryLimit     = 3
    }
  })

  depends_on = [helm_release.crossplane]
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

# Azure Provider Config (credentials)
resource "kubectl_manifest" "azure_provider_config" {
  count = var.enabled && var.provider_configs.azure.enabled ? 1 : 0

  yaml_body = yamlencode({
    apiVersion = "azure.crossplane.io/v1beta1"
    kind       = "ProviderConfig"
    metadata = {
      name = "default"
      labels = {
        "app.kubernetes.io/managed-by" = "terraform"
        "msdp.platform/component"      = "crossplane"
        "msdp.platform/provider"       = "azure"
      }
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

# AWS Provider Config (credentials)
resource "kubectl_manifest" "aws_provider_config" {
  count = var.enabled && var.provider_configs.aws.enabled ? 1 : 0

  yaml_body = yamlencode({
    apiVersion = "aws.crossplane.io/v1beta1"
    kind       = "ProviderConfig"
    metadata = {
      name = "default"
      labels = {
        "app.kubernetes.io/managed-by" = "terraform"
        "msdp.platform/component"      = "crossplane"
        "msdp.platform/provider"       = "aws"
      }
    }
    spec = {
      credentials = {
        source = "Secret"
        secretRef = {
          namespace = kubernetes_namespace.crossplane_system[0].metadata[0].name
          name      = kubernetes_secret.aws_credentials[0].metadata[0].name
          key       = "creds"
        }
      }
    }
  })

  depends_on = [time_sleep.wait_for_providers]
}

# Kubernetes Provider Config
resource "kubectl_manifest" "kubernetes_provider_config" {
  count = var.enabled && var.provider_configs.kubernetes.enabled ? 1 : 0

  yaml_body = yamlencode({
    apiVersion = "kubernetes.crossplane.io/v1alpha1"
    kind       = "ProviderConfig"
    metadata = {
      name = "default"
      labels = {
        "app.kubernetes.io/managed-by" = "terraform"
        "msdp.platform/component"      = "crossplane"
        "msdp.platform/provider"       = "kubernetes"
      }
    }
    spec = {
      credentials = {
        source = "InjectedIdentity"
      }
    }
  })

  depends_on = [time_sleep.wait_for_providers]
}

# Outputs following your convention
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
    azure      = var.provider_configs.azure.enabled
    aws        = var.provider_configs.aws.enabled
    kubernetes = var.provider_configs.kubernetes.enabled
  } : null
}
