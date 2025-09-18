# ArgoCD Latest Version Terraform Module for MSDP Platform Engineering

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

# Load configuration
locals {
  component_config = var.component_config
  namespace        = var.namespace
  chart_version    = var.component_config.chart_version
  
  # MSDP-specific labels following your conventions
  common_labels = {
    "app.kubernetes.io/name"       = "argocd"
    "app.kubernetes.io/instance"   = "msdp-argocd"
    "app.kubernetes.io/version"    = local.chart_version
    "app.kubernetes.io/component"  = "gitops-engine"
    "app.kubernetes.io/part-of"    = "msdp-platform-engineering"
    "app.kubernetes.io/managed-by" = "terraform"
    "msdp.platform/component"      = "argocd"
    "msdp.platform/environment"    = var.environment
  }
  
  # ArgoCD values configuration
  argocd_values = var.component_config.values
}

# ArgoCD namespace
resource "kubernetes_namespace" "argocd" {
  metadata {
    name   = local.namespace
    labels = local.common_labels
  }
}

# Repository credentials secret for MSDP repositories
resource "kubernetes_secret" "msdp_repo_credentials" {
  metadata {
    name      = "msdp-repo-credentials"
    namespace = kubernetes_namespace.argocd.metadata[0].name
    labels = merge(local.common_labels, {
      "argocd.argoproj.io/secret-type" = "repository"
    })
  }
  
  data = {
    type     = "git"
    url      = "https://github.com/msdp-platform"
    username = var.github_username
    password = var.github_token
  }
  
  type = "Opaque"
}

# ArgoCD configuration secret
resource "kubernetes_secret" "argocd_secret" {
  metadata {
    name      = "argocd-secret"
    namespace = kubernetes_namespace.argocd.metadata[0].name
    labels    = local.common_labels
  }
  
  data = {
    # Generate secure admin password
    "admin.password" = bcrypt(var.argocd_admin_password)
    
    # Server secret key for JWT tokens
    "server.secretkey" = base64encode(random_password.argocd_server_secret.result)
  }
  
  type = "Opaque"
}

# Generate secure server secret
resource "random_password" "argocd_server_secret" {
  length  = 32
  special = true
}

# ArgoCD Helm release
resource "helm_release" "argocd" {
  name       = "argocd"
  repository = local.component_config.repository
  chart      = "argo-cd"
  version    = local.chart_version
  namespace  = kubernetes_namespace.argocd.metadata[0].name
  
  # ArgoCD values with MSDP-specific configuration
  values = [
    yamlencode({
      # Global configuration
      global = {
        image = {
          tag = var.component_config.app_version
        }
      }
      
      # Server configuration
      server = merge(local.argocd_values.server, {
        # Additional MSDP-specific server config
        config = merge(local.argocd_values.server.config, {
          # Application instance label key
          "application.instanceLabelKey" = "argocd.argoproj.io/instance"
          
          # Resource customizations for MSDP
          "resource.customizations.health.msdp.platform_v1alpha1_MSDPService" = <<-EOT
            hs = {}
            if obj.status ~= nil then
              if obj.status.conditions ~= nil then
                for i, condition in ipairs(obj.status.conditions) do
                  if condition.type == "Ready" and condition.status == "True" then
                    hs.status = "Healthy"
                    hs.message = "MSDP Service is ready"
                    return hs
                  end
                end
              end
            end
            hs.status = "Progressing"
            hs.message = "Waiting for MSDP Service"
            return hs
          EOT
        })
        
        # RBAC configuration for MSDP teams
        rbacConfig = {
          "policy.default" = "role:readonly"
          "policy.csv" = <<-EOT
            # MSDP Platform Team - Full access
            p, role:msdp-platform-admin, applications, *, */*, allow
            p, role:msdp-platform-admin, clusters, *, *, allow
            p, role:msdp-platform-admin, repositories, *, *, allow
            
            # MSDP Frontend Team - Application access only
            p, role:msdp-frontend-dev, applications, *, msdp-frontend/*, allow
            p, role:msdp-frontend-dev, repositories, get, msdp-platform/msdp-*-frontends, allow
            
            # Group mappings (for future Azure AD integration)
            g, msdp-platform:platform-team, role:msdp-platform-admin
            g, msdp-platform:frontend-team, role:msdp-frontend-dev
          EOT
        }
      })
      
      # Repository server configuration
      repoServer = {
        resources = {
          requests = {
            memory = "512Mi"
            cpu    = "250m"
          }
          limits = {
            memory = "1Gi"
            cpu    = "500m"
          }
        }
      }
      
      # Application controller configuration
      controller = {
        resources = {
          requests = {
            memory = "1Gi"
            cpu    = "500m"
          }
          limits = {
            memory = "2Gi"
            cpu    = "1000m"
          }
        }
        
        # Metrics configuration
        metrics = {
          enabled = true
          serviceMonitor = {
            enabled = true
          }
        }
      }
      
      # Redis configuration for HA
      redis = local.argocd_values.redis
      
      # Dex configuration (for OIDC)
      dex = {
        enabled = false  # Disable for now, enable when Azure AD is configured
      }
      
      # Configurations for MSDP repositories
      configs = {
        repositories = local.argocd_values.configs.repositories
        
        # Cluster configuration
        clusters = [
          {
            name   = var.cluster_name
            server = "https://kubernetes.default.svc"
            config = {
              bearerToken = ""
              tlsClientConfig = {
                insecure = false
              }
            }
          }
        ]
      }
    })
  ]
  
  timeout         = 600
  wait            = true
  wait_for_jobs   = true
  atomic          = true
  cleanup_on_fail = true
  
  depends_on = [
    kubernetes_namespace.argocd,
    kubernetes_secret.msdp_repo_credentials,
    kubernetes_secret.argocd_secret
  ]
}

# MSDP Application definitions for ArgoCD
resource "kubectl_manifest" "msdp_platform_application" {
  yaml_body = yamlencode({
    apiVersion = "argoproj.io/v1alpha1"
    kind       = "Application"
    metadata = {
      name      = "msdp-platform"
      namespace = kubernetes_namespace.argocd.metadata[0].name
      labels    = local.common_labels
      finalizers = ["resources-finalizer.argocd.argoproj.io"]
    }
    spec = {
      project = "default"
      
      source = {
        repoURL        = "https://github.com/msdp-platform/msdp-platform-core"
        targetRevision = "dev"
        path           = "k8s/platform"
      }
      
      destination = {
        server    = "https://kubernetes.default.svc"
        namespace = "msdp-platform"
      }
      
      syncPolicy = {
        automated = {
          prune    = true
          selfHeal = true
        }
        syncOptions = [
          "CreateNamespace=true",
          "PrunePropagationPolicy=foreground",
          "PruneLast=true"
        ]
      }
      
      # Health check configuration
      ignoreDifferences = [
        {
          group = "apps"
          kind  = "Deployment"
          jsonPointers = ["/spec/replicas"]
        }
      ]
    }
  })
  
  depends_on = [helm_release.argocd]
}

# Outputs
output "argocd_namespace" {
  description = "ArgoCD namespace"
  value       = kubernetes_namespace.argocd.metadata[0].name
}

output "argocd_version" {
  description = "Deployed ArgoCD version"
  value       = helm_release.argocd.version
}

output "argocd_admin_password" {
  description = "ArgoCD admin password (sensitive)"
  value       = var.argocd_admin_password
  sensitive   = true
}

output "helm_release_status" {
  description = "ArgoCD Helm release status"
  value       = helm_release.argocd.status
}
