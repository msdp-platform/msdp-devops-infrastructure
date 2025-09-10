# Helm Charts for All Platform Components

# Karpenter Helm Chart
resource "helm_release" "karpenter" {
  namespace        = "karpenter"
  create_namespace = true

  name       = "karpenter"
  repository = "oci://public.ecr.aws/karpenter"
  chart      = "karpenter"
  version    = var.karpenter_version

  depends_on = [
    null_resource.wait_for_cluster,
    aws_iam_instance_profile.karpenter,
    aws_sqs_queue.karpenter
  ]

  set {
    name  = "settings.aws.clusterName"
    value = module.eks.cluster_name
  }

  set {
    name  = "settings.aws.defaultInstanceProfile"
    value = aws_iam_instance_profile.karpenter.name
  }

  set {
    name  = "settings.aws.interruptionQueue"
    value = aws_sqs_queue.karpenter.name
  }

  set {
    name  = "serviceAccount.annotations.eks\\.amazonaws\\.com/role-arn"
    value = aws_iam_role.karpenter_controller.arn
  }

  set {
    name  = "controller.resources.requests.cpu"
    value = "1"
  }

  set {
    name  = "controller.resources.requests.memory"
    value = "1Gi"
  }

  set {
    name  = "controller.resources.limits.cpu"
    value = "1"
  }

  set {
    name  = "controller.resources.limits.memory"
    value = "1Gi"
  }
}

# AWS Load Balancer Controller
resource "helm_release" "aws_load_balancer_controller" {
  namespace        = "kube-system"
  create_namespace = false

  name       = "aws-load-balancer-controller"
  repository = "https://aws.github.io/eks-charts"
  chart      = "aws-load-balancer-controller"
  version    = var.aws_load_balancer_controller_version

  set {
    name  = "clusterName"
    value = module.eks.cluster_name
  }

  set {
    name  = "serviceAccount.create"
    value = "false"
  }

  set {
    name  = "serviceAccount.name"
    value = "aws-load-balancer-controller"
  }

  set {
    name  = "serviceAccount.annotations.eks\\.amazonaws\\.com/role-arn"
    value = aws_iam_role.aws_load_balancer_controller.arn
  }

  set {
    name  = "region"
    value = var.aws_region
  }

  set {
    name  = "vpcId"
    value = module.vpc.vpc_id
  }

  depends_on = [null_resource.wait_for_cluster]
}

# External DNS
resource "helm_release" "external_dns" {
  namespace        = "kube-system"
  create_namespace = false

  name       = "external-dns"
  repository = "https://kubernetes-sigs.github.io/external-dns/"
  chart      = "external-dns"
  version    = var.external_dns_version

  set {
    name  = "serviceAccount.create"
    value = "false"
  }

  set {
    name  = "serviceAccount.name"
    value = "external-dns"
  }

  set {
    name  = "serviceAccount.annotations.eks\\.amazonaws\\.com/role-arn"
    value = aws_iam_role.external_dns.arn
  }

  set {
    name  = "provider"
    value = "aws"
  }

  set {
    name  = "aws.region"
    value = var.aws_region
  }

  set {
    name  = "aws.zoneType"
    value = "public"
  }

  set {
    name  = "domainFilters[0]"
    value = var.domain_name
  }

  set {
    name  = "txtOwnerId"
    value = module.eks.cluster_name
  }

  set {
    name  = "aws.zoneId"
    value = var.create_route53_zone ? aws_route53_zone.main[0].zone_id : var.route53_zone_id
  }

  set {
    name  = "policy"
    value = "sync"
  }

  depends_on = [null_resource.wait_for_cluster]
}

# Cert-Manager
resource "helm_release" "cert_manager" {
  namespace        = "cert-manager"
  create_namespace = true

  name       = "cert-manager"
  repository = "https://charts.jetstack.io"
  chart      = "cert-manager"
  version    = var.cert_manager_version

  set {
    name  = "installCRDs"
    value = "true"
  }

  set {
    name  = "serviceAccount.create"
    value = "false"
  }

  set {
    name  = "serviceAccount.name"
    value = "cert-manager"
  }

  set {
    name  = "serviceAccount.annotations.eks\\.amazonaws\\.com/role-arn"
    value = aws_iam_role.cert_manager.arn
  }

  set {
    name  = "global.leaderElection.namespace"
    value = "cert-manager"
  }

  depends_on = [null_resource.wait_for_cluster]
}

# Secrets Store CSI Driver
resource "helm_release" "secrets_store_csi_driver" {
  namespace        = "kube-system"
  create_namespace = false

  name       = "secrets-store-csi-driver"
  repository = "https://kubernetes-sigs.github.io/secrets-store-csi-driver/charts"
  chart      = "secrets-store-csi-driver"
  version    = var.secrets_store_csi_version

  set {
    name  = "syncSecret.enabled"
    value = "true"
  }

  set {
    name  = "enableSecretRotation"
    value = "true"
  }

  set {
    name  = "rotationPollInterval"
    value = "2m"
  }

  depends_on = [null_resource.wait_for_cluster]
}

# AWS Secrets Manager Provider
resource "helm_release" "secrets_store_csi_aws_provider" {
  namespace        = "kube-system"
  create_namespace = false

  name       = "secrets-store-csi-driver-provider-aws"
  repository = "https://aws.github.io/secrets-store-csi-driver-provider-aws"
  chart      = "secrets-store-csi-driver-provider-aws"
  version    = var.secrets_store_csi_aws_provider_version

  depends_on = [helm_release.secrets_store_csi_driver]
}

# NGINX Ingress Controller
resource "helm_release" "nginx_ingress" {
  namespace        = "ingress-nginx"
  create_namespace = true

  name       = "ingress-nginx"
  repository = "https://kubernetes.github.io/ingress-nginx"
  chart      = "ingress-nginx"
  version    = var.nginx_ingress_version

  set {
    name  = "controller.service.type"
    value = "LoadBalancer"
  }

  set {
    name  = "controller.service.annotations.service\\.beta\\.kubernetes\\.io/aws-load-balancer-type"
    value = "nlb"
  }

  set {
    name  = "controller.service.annotations.service\\.beta\\.kubernetes\\.io/aws-load-balancer-scheme"
    value = "internet-facing"
  }

  set {
    name  = "controller.service.annotations.service\\.beta\\.kubernetes\\.io/aws-load-balancer-cross-zone-load-balancing-enabled"
    value = "true"
  }

  set {
    name  = "controller.metrics.enabled"
    value = "true"
  }

  set {
    name  = "controller.metrics.serviceMonitor.enabled"
    value = "true"
  }

  set {
    name  = "controller.metrics.serviceMonitor.namespace"
    value = "monitoring"
  }

  depends_on = [module.eks, helm_release.aws_load_balancer_controller]
}

# Prometheus
resource "helm_release" "prometheus" {
  namespace        = "monitoring"
  create_namespace = true

  name       = "prometheus"
  repository = "https://prometheus-community.github.io/helm-charts"
  chart      = "kube-prometheus-stack"
  version    = var.prometheus_version

  values = [
    yamlencode({
      prometheus = {
        prometheusSpec = {
          serviceMonitorSelectorNilUsesHelmValues = false
          ruleSelectorNilUsesHelmValues           = false
          retention                               = "30d"
          storageSpec = {
            volumeClaimTemplate = {
              spec = {
                storageClassName = "gp2"
                accessModes      = ["ReadWriteOnce"]
                resources = {
                  requests = {
                    storage = "50Gi"
                  }
                }
              }
            }
          }
        }
      }
      grafana = {
        enabled       = true
        adminPassword = "admin123"
        persistence = {
          enabled          = true
          storageClassName = "gp2"
          size             = "10Gi"
        }
        service = {
          type = "LoadBalancer"
          annotations = {
            "service.beta.kubernetes.io/aws-load-balancer-type"   = "nlb"
            "service.beta.kubernetes.io/aws-load-balancer-scheme" = "internet-facing"
          }
        }
      }
      alertmanager = {
        alertmanagerSpec = {
          storage = {
            volumeClaimTemplate = {
              spec = {
                storageClassName = "gp2"
                accessModes      = ["ReadWriteOnce"]
                resources = {
                  requests = {
                    storage = "10Gi"
                  }
                }
              }
            }
          }
        }
      }
    })
  ]

  depends_on = [null_resource.wait_for_cluster]
}

# ArgoCD
resource "helm_release" "argocd" {
  namespace        = "argocd"
  create_namespace = true

  name       = "argocd"
  repository = "https://argoproj.github.io/argo-helm"
  chart      = "argo-cd"
  version    = var.argocd_version

  values = [
    yamlencode({
      server = {
        service = {
          type = "LoadBalancer"
          annotations = {
            "service.beta.kubernetes.io/aws-load-balancer-type"   = "nlb"
            "service.beta.kubernetes.io/aws-load-balancer-scheme" = "internet-facing"
          }
        }
        ingress = {
          enabled          = true
          ingressClassName = "nginx"
          annotations = {
            "cert-manager.io/cluster-issuer"               = "letsencrypt-prod"
            "nginx.ingress.kubernetes.io/ssl-redirect"     = "true"
            "nginx.ingress.kubernetes.io/backend-protocol" = "HTTP"
          }
          hosts = [
            "argocd.${var.domain_name}"
          ]
          tls = [
            {
              secretName = "argocd-server-tls"
              hosts = [
                "argocd.${var.domain_name}"
              ]
            }
          ]
        }
      }
      configs = {
        params = {
          "server.insecure" = "true"
        }
      }
      controller = {
        serviceAccount = {
          annotations = {
            "eks.amazonaws.com/role-arn" = aws_iam_role.argocd.arn
          }
        }
      }
    })
  ]

  depends_on = [module.eks, helm_release.nginx_ingress, helm_release.cert_manager]
}

# Crossplane
resource "helm_release" "crossplane" {
  namespace        = "crossplane-system"
  create_namespace = true

  name       = "crossplane"
  repository = "https://charts.crossplane.io/stable"
  chart      = "crossplane"
  version    = var.crossplane_version

  set {
    name  = "args[0]"
    value = "--enable-external-secret-stores"
  }

  set {
    name  = "serviceAccount.annotations.eks\\.amazonaws\\.com/role-arn"
    value = aws_iam_role.crossplane.arn
  }

  depends_on = [null_resource.wait_for_cluster]
}

# AWS Controllers for Kubernetes (ACK)
resource "helm_release" "ack_s3" {
  namespace        = "ack-system"
  create_namespace = true

  name       = "ack-s3-controller"
  repository = "oci://public.ecr.aws/aws-controllers-k8s"
  chart      = "ack-s3-controller"
  version    = var.ack_s3_version

  set {
    name  = "aws.region"
    value = var.aws_region
  }

  depends_on = [null_resource.wait_for_cluster]
}

resource "helm_release" "ack_rds" {
  namespace        = "ack-system"
  create_namespace = true

  name       = "ack-rds-controller"
  repository = "oci://public.ecr.aws/aws-controllers-k8s"
  chart      = "ack-rds-controller"
  version    = var.ack_rds_version

  set {
    name  = "aws.region"
    value = var.aws_region
  }

  depends_on = [null_resource.wait_for_cluster]
}

# Backstage
resource "helm_release" "backstage" {
  namespace        = "backstage"
  create_namespace = true

  name       = "backstage"
  repository = "https://backstage.github.io/charts"
  chart      = "backstage"
  version    = var.backstage_version

  values = [
    yamlencode({
      backstage = {
        appConfig = {
          app = {
            title   = "MSDP Developer Portal"
            baseUrl = "https://backstage.${var.domain_name}"
          }
          backend = {
            baseUrl = "https://backstage.${var.domain_name}"
            listen = {
              port = 7007
            }
            database = {
              client = "pg"
              connection = {
                host     = aws_rds_cluster.backstage_postgres.endpoint
                port     = aws_rds_cluster.backstage_postgres.port
                user     = aws_rds_cluster.backstage_postgres.master_username
                password = aws_rds_cluster.backstage_postgres.master_password
                database = aws_rds_cluster.backstage_postgres.database_name
                ssl = {
                  rejectUnauthorized = false
                }
              }
            }
          }
        }
      }
      ingress = {
        enabled          = true
        ingressClassName = "nginx"
        annotations = {
          "cert-manager.io/cluster-issuer"           = "letsencrypt-prod"
          "nginx.ingress.kubernetes.io/ssl-redirect" = "true"
        }
        hosts = [
          {
            host = "backstage.${var.domain_name}"
            paths = [
              {
                path     = "/"
                pathType = "Prefix"
              }
            ]
          }
        ]
        tls = [
          {
            secretName = "backstage-tls"
            hosts = [
              "backstage.${var.domain_name}"
            ]
          }
        ]
      }
    })
  ]

  depends_on = [module.eks, helm_release.nginx_ingress, helm_release.cert_manager, aws_rds_cluster.backstage_postgres]
}
