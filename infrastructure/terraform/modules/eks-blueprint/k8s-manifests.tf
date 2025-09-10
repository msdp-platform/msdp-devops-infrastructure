# Kubernetes Manifests for Platform Components

# Karpenter EC2NodeClass - ARM-based (Graviton)
resource "kubectl_manifest" "karpenter_nodeclass_arm" {
  yaml_body = yamlencode({
    apiVersion = "karpenter.k8s.aws/v1beta1"
    kind       = "EC2NodeClass"
    metadata = {
      name = "arm64"
    }
    spec = {
      # IAM role for nodes
      role = aws_iam_role.karpenter_node_instance_profile.name

      # AMI family - ARM-based
      amiFamily = "AL2"

      # Instance store policy
      instanceStorePolicy = "RAID0"

      # User data for node initialization
      userData = base64encode(templatefile("${path.module}/userdata.sh", {
        cluster_name     = local.name
        cluster_endpoint = module.eks.cluster_endpoint
        cluster_ca       = module.eks.cluster_certificate_authority_data
      }))

      # Block device mappings
      blockDeviceMappings = [
        {
          deviceName = "/dev/xvda"
          ebs = {
            volumeSize          = "50Gi"
            volumeType          = "gp3"
            iops                = 3000
            throughput          = 125
            encrypted           = true
            deleteOnTermination = true
          }
        }
      ]

      # Subnet selector
      subnetSelectorTerms = [
        {
          tags = {
            "karpenter.sh/discovery" = local.name
          }
        }
      ]

      # Security group selector
      securityGroupSelectorTerms = [
        {
          tags = {
            "karpenter.sh/discovery" = local.name
          }
        }
      ]

      # Instance metadata options
      metadataOptions = {
        httpEndpoint            = "enabled"
        httpProtocolIPv6        = "disabled"
        httpPutResponseHopLimit = 2
        httpTokens              = "required"
      }
    }
  })

  depends_on = [helm_release.karpenter]
}

# Karpenter EC2NodeClass - x86-based
resource "kubectl_manifest" "karpenter_nodeclass_x86" {
  yaml_body = yamlencode({
    apiVersion = "karpenter.k8s.aws/v1beta1"
    kind       = "EC2NodeClass"
    metadata = {
      name = "amd64"
    }
    spec = {
      # IAM role for nodes
      role = aws_iam_role.karpenter_node_instance_profile.name

      # AMI family - x86-based
      amiFamily = "AL2"

      # Instance store policy
      instanceStorePolicy = "RAID0"

      # User data for node initialization
      userData = base64encode(templatefile("${path.module}/userdata.sh", {
        cluster_name     = local.name
        cluster_endpoint = module.eks.cluster_endpoint
        cluster_ca       = module.eks.cluster_certificate_authority_data
      }))

      # Block device mappings
      blockDeviceMappings = [
        {
          deviceName = "/dev/xvda"
          ebs = {
            volumeSize          = "50Gi"
            volumeType          = "gp3"
            iops                = 3000
            throughput          = 125
            encrypted           = true
            deleteOnTermination = true
          }
        }
      ]

      # Subnet selector
      subnetSelectorTerms = [
        {
          tags = {
            "karpenter.sh/discovery" = local.name
          }
        }
      ]

      # Security group selector
      securityGroupSelectorTerms = [
        {
          tags = {
            "karpenter.sh/discovery" = local.name
          }
        }
      ]

      # Instance metadata options
      metadataOptions = {
        httpEndpoint            = "enabled"
        httpProtocolIPv6        = "disabled"
        httpPutResponseHopLimit = 2
        httpTokens              = "required"
      }
    }
  })

  depends_on = [helm_release.karpenter]
}

# Karpenter NodePool - Cost Optimized with Mixed Architecture
resource "kubectl_manifest" "karpenter_nodepool_cost_optimized" {
  yaml_body = yamlencode({
    apiVersion = "karpenter.sh/v1beta1"
    kind       = "NodePool"
    metadata = {
      name = "cost-optimized"
    }
    spec = {
      template = {
        metadata = {
          labels = {
            "node-type"              = "cost-optimized"
            "karpenter.sh/discovery" = local.name
          }
        }
        spec = {
          # Node requirements - Mixed architecture for cost optimization
          requirements = [
            {
              key      = "karpenter.sh/capacity-type"
              operator = "In"
              values   = ["spot"]
            },
            {
              key      = "kubernetes.io/arch"
              operator = "In"
              values   = ["arm64", "amd64"]
            },
            {
              key      = "node.kubernetes.io/instance-type"
              operator = "In"
              values   = var.karpenter_instance_types
            }
          ]

          # Taints to prevent system workloads
          taints = [
            {
              key    = "workload-type"
              value  = "user"
              effect = "NO_SCHEDULE"
            }
          ]

          # Startup taint to prevent immediate scheduling
          startupTaints = [
            {
              key    = "karpenter.sh/startup"
              value  = "true"
              effect = "NO_SCHEDULE"
            }
          ]
        }
      }

      # Limits to prevent 0 scaling
      limits = {
        cpu    = "1000"
        memory = "1000Gi"
      }

      # Disruption settings
      disruption = {
        # Ensure minimum nodes are always available
        consolidateAfter  = "30s"
        consolidatePolicy = "WhenEmpty"
        expireAfter       = "2160h" # 90 days
      }
    }
  })

  depends_on = [helm_release.karpenter]
}

# GPU NodePool removed - not needed for this setup

# Karpenter NodePool - Memory Optimized
resource "kubectl_manifest" "karpenter_nodepool_memory" {
  yaml_body = yamlencode({
    apiVersion = "karpenter.sh/v1beta1"
    kind       = "NodePool"
    metadata = {
      name = "memory-optimized"
    }
    spec = {
      template = {
        metadata = {
          labels = {
            "node-type"              = "memory-optimized"
            "karpenter.sh/discovery" = local.name
          }
        }
        spec = {
          requirements = [
            {
              key      = "karpenter.sh/capacity-type"
              operator = "In"
              values   = ["spot"]
            },
            {
              key      = "kubernetes.io/arch"
              operator = "In"
              values   = ["arm64", "amd64"]
            },
            {
              key      = "node.kubernetes.io/instance-type"
              operator = "In"
              values = [
                # ARM-based memory-optimized instances
                "t4g.medium", "t4g.large", "t4g.xlarge", "t4g.2xlarge", "t4g.4xlarge",
                "r6g.medium", "r6g.large", "r6g.xlarge", "r6g.2xlarge", "r6g.4xlarge",
                "r6g.8xlarge", "r6g.12xlarge", "r6g.16xlarge",
                "m6g.medium", "m6g.large", "m6g.xlarge", "m6g.2xlarge", "m6g.4xlarge",
                "m6g.8xlarge", "m6g.12xlarge", "m6g.16xlarge",
                # x86-based memory-optimized instances
                "t3.medium", "t3.large", "t3.xlarge", "t3.2xlarge",
                "t3a.medium", "t3a.large", "t3a.xlarge", "t3a.2xlarge",
                "r5.medium", "r5.large", "r5.xlarge", "r5.2xlarge", "r5.4xlarge",
                "r5a.medium", "r5a.large", "r5a.xlarge", "r5a.2xlarge", "r5a.4xlarge",
                "m5.medium", "m5.large", "m5.xlarge", "m5.2xlarge", "m5.4xlarge",
                "m5a.medium", "m5a.large", "m5a.xlarge", "m5a.2xlarge", "m5a.4xlarge"
              ]
            }
          ]

          nodeClassRef = {
            apiVersion = "karpenter.k8s.aws/v1beta1"
            kind       = "EC2NodeClass"
            name       = "default"
          }

          taints = [
            {
              key    = "workload-type"
              value  = "memory-intensive"
              effect = "NO_SCHEDULE"
            }
          ]
        }
      }

      limits = {
        cpu    = "100"
        memory = "2000Gi"
      }

      disruption = {
        consolidateAfter  = "30s"
        consolidatePolicy = "WhenEmpty"
        expireAfter       = "2160h"
      }
    }
  })

  depends_on = [helm_release.karpenter]
}

# Karpenter NodePool - Minimum Nodes (prevents 0 scaling)
resource "kubectl_manifest" "karpenter_nodepool_minimum" {
  yaml_body = yamlencode({
    apiVersion = "karpenter.sh/v1beta1"
    kind       = "NodePool"
    metadata = {
      name = "minimum-nodes"
    }
    spec = {
      template = {
        metadata = {
          labels = {
            "node-type"              = "minimum"
            "karpenter.sh/discovery" = local.name
          }
        }
        spec = {
          requirements = [
            {
              key      = "karpenter.sh/capacity-type"
              operator = "In"
              values   = ["spot"]
            },
            {
              key      = "kubernetes.io/arch"
              operator = "In"
              values   = ["arm64", "amd64"]
            },
            {
              key      = "node.kubernetes.io/instance-type"
              operator = "In"
              values = [
                # ARM-based instances for minimum nodes
                "t4g.medium", "t4g.large", "t4g.xlarge",
                "r6g.medium", "r6g.large", "r6g.xlarge",
                "m6g.medium", "m6g.large", "m6g.xlarge",
                # x86-based instances for minimum nodes
                "t3.medium", "t3.large", "t3.xlarge",
                "t3a.medium", "t3a.large", "t3a.xlarge",
                "m5.medium", "m5.large", "m5.xlarge",
                "m5a.medium", "m5a.large", "m5a.xlarge"
              ]
            }
          ]

          nodeClassRef = {
            apiVersion = "karpenter.k8s.aws/v1beta1"
            kind       = "EC2NodeClass"
            name       = "default"
          }
        }
      }

      # Ensure minimum nodes are always available
      limits = {
        cpu    = "4"
        memory = "8Gi"
      }

      # Disruption settings to prevent 0 scaling
      disruption = {
        consolidateAfter  = "60s"
        consolidatePolicy = "WhenUnderutilized"
        expireAfter       = "2160h"
      }
    }
  })

  depends_on = [helm_release.karpenter]
}

# Cert-Manager ClusterIssuer for Let's Encrypt
resource "kubectl_manifest" "cert_manager_cluster_issuer" {
  yaml_body = yamlencode({
    apiVersion = "cert-manager.io/v1"
    kind       = "ClusterIssuer"
    metadata = {
      name = "letsencrypt-prod"
    }
    spec = {
      acme = {
        server = "https://acme-v02.api.letsencrypt.org/directory"
        email  = var.letsencrypt_email
        privateKeySecretRef = {
          name = "letsencrypt-prod"
        }
        solvers = [
          {
            dns01 = {
              route53 = {
                region       = var.aws_region
                hostedZoneID = var.create_route53_zone ? aws_route53_zone.main[0].zone_id : var.route53_zone_id
              }
            }
          }
        ]
      }
    }
  })

  depends_on = [helm_release.cert_manager]
}

# Secrets Store CSI Driver SecretProviderClass
resource "kubectl_manifest" "secrets_store_csi_secret_provider_class" {
  yaml_body = yamlencode({
    apiVersion = "secrets-store.csi.x-k8s.io/v1"
    kind       = "SecretProviderClass"
    metadata = {
      name      = "aws-secrets"
      namespace = "default"
    }
    spec = {
      provider = "aws"
      parameters = {
        objects = jsonencode([
          {
            objectName    = "example-secret"
            objectType    = "secretsmanager"
            objectVersion = "AWSCURRENT"
          }
        ])
      }
      secretObjects = [
        {
          secretName = "example-secret"
          type       = "Opaque"
          data = [
            {
              objectName = "example-secret"
              key        = "username"
            }
          ]
        }
      ]
    }
  })

  depends_on = [helm_release.secrets_store_csi_driver]
}

# Crossplane AWS Provider
resource "kubectl_manifest" "crossplane_aws_provider" {
  yaml_body = yamlencode({
    apiVersion = "pkg.crossplane.io/v1"
    kind       = "Provider"
    metadata = {
      name = "provider-aws"
    }
    spec = {
      package = "xpkg.upbound.io/crossplane-contrib/provider-aws:v0.44.0"
    }
  })

  depends_on = [helm_release.crossplane]
}

# Crossplane AWS Provider Config
resource "kubectl_manifest" "crossplane_aws_provider_config" {
  yaml_body = yamlencode({
    apiVersion = "aws.crossplane.io/v1beta1"
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

  depends_on = [kubectl_manifest.crossplane_aws_provider]
}

# ArgoCD Application for Platform Components
resource "kubectl_manifest" "argocd_platform_app" {
  yaml_body = yamlencode({
    apiVersion = "argoproj.io/v1alpha1"
    kind       = "Application"
    metadata = {
      name      = "platform-components"
      namespace = "argocd"
    }
    spec = {
      project = "default"
      source = {
        repoURL        = "https://github.com/your-org/platform-components"
        targetRevision = "HEAD"
        path           = "manifests"
      }
      destination = {
        server    = "https://kubernetes.default.svc"
        namespace = "default"
      }
      syncPolicy = {
        automated = {
          prune    = true
          selfHeal = true
        }
        syncOptions = [
          "CreateNamespace=true"
        ]
      }
    }
  })

  depends_on = [helm_release.argocd]
}

# ServiceMonitor for Karpenter
resource "kubectl_manifest" "karpenter_servicemonitor" {
  yaml_body = yamlencode({
    apiVersion = "monitoring.coreos.com/v1"
    kind       = "ServiceMonitor"
    metadata = {
      name      = "karpenter"
      namespace = "monitoring"
      labels = {
        app = "karpenter"
      }
    }
    spec = {
      selector = {
        matchLabels = {
          app = "karpenter"
        }
      }
      endpoints = [
        {
          port     = "metrics"
          interval = "30s"
        }
      ]
    }
  })

  depends_on = [helm_release.prometheus, helm_release.karpenter]
}

# Grafana Dashboard for Karpenter
resource "kubectl_manifest" "karpenter_grafana_dashboard" {
  yaml_body = yamlencode({
    apiVersion = "v1"
    kind       = "ConfigMap"
    metadata = {
      name      = "karpenter-dashboard"
      namespace = "monitoring"
      labels = {
        grafana_dashboard = "1"
      }
    }
    data = {
      "karpenter.json" = jsonencode({
        dashboard = {
          title = "Karpenter Dashboard"
          panels = [
            {
              title = "Node Count"
              type  = "stat"
              targets = [
                {
                  expr = "count(karpenter_nodes_allocatable)"
                }
              ]
            }
          ]
        }
      })
    }
  })

  depends_on = [helm_release.prometheus]
}
