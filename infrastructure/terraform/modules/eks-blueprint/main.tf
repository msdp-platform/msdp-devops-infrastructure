# Comprehensive EKS Blueprint with All Platform Components
# This module creates a complete EKS platform with all required components using AWS EKS Blueprints Addons

terraform {
  required_version = ">= 1.0"
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 6.0"
    }
    helm = {
      source  = "hashicorp/helm"
      version = "~> 2.0"
    }
    kubectl = {
      source  = "gavinbunney/kubectl"
      version = "~> 1.14"
    }
  }
}

# Data sources
data "aws_availability_zones" "available" {
  state = "available"
}

data "aws_caller_identity" "current" {}

# Local values
locals {
  name   = var.cluster_name
  region = var.aws_region

  vpc_cidr = var.vpc_cidr
  azs      = slice(data.aws_availability_zones.available.names, 0, 3)

  tags = merge(var.tags, {
    Blueprint  = local.name
    GithubRepo = "msdp-devops-infrastructure"
  })
}

# VPC
module "vpc" {
  source  = "terraform-aws-modules/vpc/aws"
  version = "5.1.2"

  name = "${local.name}-vpc"
  cidr = local.vpc_cidr

  azs             = local.azs
  private_subnets = [for k, v in local.azs : cidrsubnet(local.vpc_cidr, 4, k)]
  public_subnets  = [for k, v in local.azs : cidrsubnet(local.vpc_cidr, 8, k + 48)]
  intra_subnets   = [for k, v in local.azs : cidrsubnet(local.vpc_cidr, 8, k + 52)]

  enable_nat_gateway   = true
  single_nat_gateway   = true
  enable_dns_hostnames = true
  enable_dns_support   = true

  public_subnet_tags = {
    "kubernetes.io/role/elb" = 1
  }

  private_subnet_tags = {
    "kubernetes.io/role/internal-elb" = 1
    "karpenter.sh/discovery"          = local.name
  }

  tags = local.tags
}

# EKS Cluster with Fargate Profiles
module "eks" {
  source  = "terraform-aws-modules/eks/aws"
  version = "~> 21.1.5"

  name               = local.name
  kubernetes_version = var.kubernetes_version

  vpc_id                 = module.vpc.vpc_id
  subnet_ids             = module.vpc.private_subnets
  endpoint_public_access = true

  access_entries = {
    github_actions = {
      principal_arn = "arn:aws:iam::319422413814:role/GitHubActions-Role"
      policy_associations = {
        admin = {
          policy_arn = "arn:aws:eks::aws:cluster-access-policy/AmazonEKSClusterAdminPolicy"
          access_scope = {
            type = "cluster"
          }
        }
      }
    }
  }

  # EKS Managed Node Groups - ARM-based system nodes (spot only for cost optimization)
  eks_managed_node_groups = {
    # Critical system nodes - ARM-based spot instances for cost savings
    system = {
      name = "system"

      instance_types = ["t4g.medium"]

      min_size     = 1
      max_size     = 3
      desired_size = 2

      # Use on-demand instances to ensure reliable creation
      capacity_type = "ON_DEMAND"

      labels = {
        "node-type"               = "system"
        "karpenter.sh/discovery"  = local.name
        "node.kubernetes.io/arch" = "arm64"
      }

      # ARM-based AMI
      ami_type = "AL2_ARM_64"
      platform = "linux"

      block_device_mappings = {
        xvda = {
          device_name = "/dev/xvda"
          ebs = {
            volume_size           = 50
            volume_type           = "gp3"
            iops                  = 3000
            throughput            = 125
            encrypted             = true
            delete_on_termination = true
          }
        }
      }
    }
  }

  # Fargate Profiles for serverless workloads
  fargate_profiles = {
    jobs = {
      name = "jobs"
      selectors = [
        {
          namespace = "jobs"
        }
      ]
    }
  }

  # Note: aws-auth configmap management is handled automatically in EKS module v20+
  # Karpenter node role is managed via EKS managed node groups and IRSA

  tags = local.tags
}

# AWS EKS Blueprints Addons - All platform components managed by official AWS module
module "eks_blueprints_addons" {
  source  = "aws-ia/eks-blueprints-addons/aws"
  version = "~> 1.22.0"

  cluster_name      = module.eks.cluster_name
  cluster_endpoint  = module.eks.cluster_endpoint
  cluster_version   = module.eks.cluster_version
  oidc_provider_arn = module.eks.oidc_provider_arn

  # EKS Add-ons
  eks_addons = {
    aws-ebs-csi-driver = {
      most_recent = true
    }
    coredns = {
      most_recent = true
    }
    vpc-cni = {
      most_recent = true
    }
    kube-proxy = {
      most_recent = true
    }
  }

  # Enable AWS Load Balancer Controller
  enable_aws_load_balancer_controller = false
  aws_load_balancer_controller = {
    helm_config = {
      values = [
        yamlencode({
          clusterName = module.eks.cluster_name
          region      = var.aws_region
          vpcId       = module.vpc.vpc_id
          serviceAccount = {
            create = true
            name   = "aws-load-balancer-controller"
            annotations = {
              "eks.amazonaws.com/role-arn" = aws_iam_role.aws_load_balancer_controller.arn
            }
          }
          admissionWebhooks = {
            failurePolicy = "Ignore"
          }
        })
      ]
    }
  }

  # Enable External DNS
  enable_external_dns = true
  external_dns = {
    helm_config = {
      namespace        = "external-dns"
      create_namespace = true
      values = [
        yamlencode({
          serviceAccount = {
            create = true
            name   = "external-dns"
            annotations = {
              "eks.amazonaws.com/role-arn" = aws_iam_role.external_dns.arn
            }
          }
          sources = ["ingress"]
          aws = {
            zoneType = "public"
            region   = var.aws_region
          }
          nodeSelector = {
            "node-type" = "system"
          }
        })
      ]
    }
  }

  # Enable Cert-Manager
  enable_cert_manager = true
  cert_manager = {
    helm_config = {
      values = [
        yamlencode({
          serviceAccount = {
            create = true
            name   = "cert-manager"
            annotations = {
              "eks.amazonaws.com/role-arn" = aws_iam_role.cert_manager.arn
            }
          }
          nodeSelector = {
            "node-type" = "system"
          }
        })
      ]
    }
  }

  # Enable Secrets Store CSI Driver
  enable_secrets_store_csi_driver = true
  secrets_store_csi_driver = {
    helm_config = {
      values = [
        yamlencode({
          serviceAccount = {
            create = true
            name   = "secrets-store-csi-driver"
            annotations = {
              "eks.amazonaws.com/role-arn" = aws_iam_role.secrets_store_csi.arn
            }
          }
          nodeSelector = {
            "node-type" = "system"
          }
        })
      ]
    }
  }

  # Enable Karpenter in Blueprints with IRSA and settings
  enable_karpenter = true
  karpenter = {
    helm_config = {
      chart_version = "v1.1.0"
      values = [
        yamlencode({
          serviceAccount = {
            create = false
            name   = "karpenter"
          }
          settings = {
            aws = {
              clusterName            = module.eks.cluster_name
              defaultInstanceProfile = aws_iam_instance_profile.karpenter.name
              interruptionQueue      = aws_sqs_queue.karpenter.name
            }
          }
        })
      ]
    }
  }
  # Enable NGINX Ingress Controller
  enable_ingress_nginx = true
  ingress_nginx = {
    helm_config = {
      values = [
        yamlencode({
          controller = {
            nodeSelector = {
              "node-type" = "system"
            }
            service = {
              type = "LoadBalancer"
              annotations = {
                "service.beta.kubernetes.io/aws-load-balancer-type"                              = "nlb"
                "service.beta.kubernetes.io/aws-load-balancer-scheme"                            = "internet-facing"
                "service.beta.kubernetes.io/aws-load-balancer-nlb-target-type"                   = "ip"
                "service.beta.kubernetes.io/aws-load-balancer-cross-zone-load-balancing-enabled" = "true"
              }
            }
          }
        })
      ]
    }
  }

  # Enable Prometheus Stack
  enable_kube_prometheus_stack = true
  kube_prometheus_stack = {
    helm_config = {
      values = [
        yamlencode({
          prometheusOperator = {
            nodeSelector = {
              "node-type" = "system"
            }
          }
          grafana = {
            enabled = true
            service = {
              type = "LoadBalancer"
            }
            nodeSelector = {
              "node-type" = "system"
            }
          }
          prometheus = {
            nodeSelector = {
              "node-type" = "system"
            }
            prometheusSpec = {
              serviceMonitorSelectorNilUsesHelmValues = false
            }
          }
          alertmanager = {
            nodeSelector = {
              "node-type" = "system"
            }
          }
          kube-state-metrics = {
            nodeSelector = {
              "node-type" = "system"
            }
          }
        })
      ]
    }
  }

  # Enable ArgoCD
  enable_argocd = true
  argocd = {
    helm_config = {
      values = [
        yamlencode({
          controller = {
            nodeSelector = {
              "node-type" = "system"
            }
          }
          server = {
            nodeSelector = {
              "node-type" = "system"
            }
            service = {
              type = "LoadBalancer"
            }
          }
          repoServer = {
            nodeSelector = {
              "node-type" = "system"
            }
          }
          applicationSet = {
            nodeSelector = {
              "node-type" = "system"
            }
          }
          dex = {
            nodeSelector = {
              "node-type" = "system"
            }
          }
          notifications = {
            nodeSelector = {
              "node-type" = "system"
            }
          }
        })
      ]
    }
  }

  tags = local.tags

  depends_on = [
    null_resource.wait_for_cluster
  ]
}

# Backstage - Developer Portal (not included in EKS Blueprints Addons)
resource "helm_release" "backstage" {
  count      = 0
  name       = "backstage"
  repository = "https://backstage.github.io/charts"
  chart      = "backstage"
  version    = "0.1.0"
  namespace  = "backstage"

  create_namespace = true

  depends_on = [
    module.eks_blueprints_addons,
    aws_rds_cluster.backstage_postgres
  ]

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
            csp = {
              "connect-src" = ["'self'", "http:", "https:"]
            }
            cors = {
              origin      = "https://backstage.${var.domain_name}"
              methods     = ["GET", "HEAD", "PATCH", "POST", "PUT", "DELETE"]
              credentials = true
            }
            database = {
              client = "pg"
              connection = {
                host     = aws_rds_cluster.backstage_postgres.endpoint
                port     = 5432
                user     = aws_rds_cluster.backstage_postgres.master_username
                password = random_password.backstage_postgres_password.result
                database = aws_rds_cluster.backstage_postgres.database_name
                ssl = {
                  rejectUnauthorized = false
                }
              }
            }
          }
          integrations = {
            github = [
              {
                host  = "github.com"
                token = var.github_token
              }
            ]
          }
        }
      }
      service = {
        type = "LoadBalancer"
        annotations = {
          "service.beta.kubernetes.io/aws-load-balancer-type" = "nlb"
        }
      }
      ingress = {
        enabled   = true
        className = "nginx"
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
            hosts      = ["backstage.${var.domain_name}"]
          }
        ]
      }
    })
  ]

  timeout = 600
}

# Crossplane - Infrastructure as Code (not included in EKS Blueprints Addons)
resource "helm_release" "crossplane" {
  name       = "crossplane"
  repository = "https://charts.crossplane.io/stable"
  chart      = "crossplane"
  version    = "1.14.1"
  namespace  = "crossplane-system"

  create_namespace = true

  depends_on = [
    module.eks_blueprints_addons
  ]

  values = [
    yamlencode({
      serviceAccount = {
        create = false
        name   = "crossplane"
        annotations = {
          "eks.amazonaws.com/role-arn" = aws_iam_role.crossplane.arn
        }
      }
    })
  ]

  timeout = 600
}

# Wait for EKS cluster to be ready and update kubeconfig
resource "null_resource" "wait_for_cluster" {
  depends_on = [module.eks]

  provisioner "local-exec" {
    command = <<-EOT
      aws eks wait cluster-active --region ${var.aws_region} --name ${module.eks.cluster_name}
      aws eks update-kubeconfig --region ${var.aws_region} --name ${module.eks.cluster_name}
      # Wait for nodes to be ready
      kubectl wait --for=condition=Ready nodes --all --timeout=300s
    EOT
  }

  triggers = {
    cluster_name     = module.eks.cluster_name
    cluster_endpoint = module.eks.cluster_endpoint
  }
}

# Wait until Karpenter controller is ready before creating NodePools
resource "null_resource" "wait_for_karpenter_ready" {
  depends_on = [module.eks_blueprints_addons, null_resource.wait_for_cluster]

  provisioner "local-exec" {
    command = <<-EOT
      aws eks update-kubeconfig --region ${var.aws_region} --name ${module.eks.cluster_name}
      # Wait for Karpenter namespace and deployment to become available
      kubectl get ns karpenter >/dev/null 2>&1 || true
      kubectl -n karpenter rollout status deploy/karpenter --timeout=600s || exit 1
    EOT
  }

  triggers = {
    cluster_name = module.eks.cluster_name
  }
}

# Karpenter Node IAM Role
resource "aws_iam_role" "karpenter_node_instance_profile" {
  name = "${local.name}-karpenter-node"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Principal = {
          Service = "ec2.amazonaws.com"
        }
      }
    ]
  })

  tags = local.tags
}

resource "aws_iam_role_policy_attachment" "karpenter_node_worker_node_policy" {
  policy_arn = "arn:aws:iam::aws:policy/AmazonEKSWorkerNodePolicy"
  role       = aws_iam_role.karpenter_node_instance_profile.name
}

resource "aws_iam_role_policy_attachment" "karpenter_node_cni_policy" {
  policy_arn = "arn:aws:iam::aws:policy/AmazonEKS_CNI_Policy"
  role       = aws_iam_role.karpenter_node_instance_profile.name
}

resource "aws_iam_role_policy_attachment" "karpenter_node_registry_policy" {
  policy_arn = "arn:aws:iam::aws:policy/AmazonEC2ContainerRegistryReadOnly"
  role       = aws_iam_role.karpenter_node_instance_profile.name
}

# Karpenter Controller IAM Role
resource "aws_iam_role" "karpenter_controller" {
  name = "${local.name}-karpenter-controller"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Principal = {
          Federated = module.eks.oidc_provider_arn
        }
        Condition = {
          StringEquals = {
            "${module.eks.oidc_provider}:sub" = "system:serviceaccount:karpenter:karpenter"
            "${module.eks.oidc_provider}:aud" = "sts.amazonaws.com"
          }
        }
      }
    ]
  })

  tags = local.tags
}

resource "aws_iam_role_policy" "karpenter_controller" {
  name = "${local.name}-karpenter-controller"
  role = aws_iam_role.karpenter_controller.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "iam:PassRole"
        ]
        Resource = aws_iam_role.karpenter_node_instance_profile.arn
        Condition = {
          StringEquals = {
            "iam:PassedToService" = "ec2.amazonaws.com"
          }
        }
      },
      {
        Effect = "Allow"
        Action = [
          "ssm:GetParameter",
          "iam:CreateInstanceProfile",
          "iam:DeleteInstanceProfile",
          "iam:AddRoleToInstanceProfile",
          "iam:RemoveRoleFromInstanceProfile",
          "iam:GetInstanceProfile",
          "iam:ListInstanceProfiles",
          "iam:ListInstanceProfilesForRole",
          "iam:GetRole",
          "ec2:DescribeImages",
          "ec2:RunInstances",
          "ec2:DescribeSubnets",
          "ec2:DescribeSecurityGroups",
          "ec2:DescribeLaunchTemplates",
          "ec2:DescribeInstances",
          "ec2:DescribeInstanceTypes",
          "ec2:DescribeInstanceTypeOfferings",
          "ec2:DescribeAvailabilityZones",
          "ec2:DeleteLaunchTemplate",
          "ec2:CreateTags",
          "ec2:CreateLaunchTemplate",
          "ec2:CreateFleet",
          "ec2:DescribeSpotPriceHistory",
          "pricing:GetProducts"
        ]
        Resource = "*"
      }
    ]
  })
}

# Note: Karpenter controller policy is an inline policy, no attachment needed

# Karpenter Instance Profile
resource "aws_iam_instance_profile" "karpenter" {
  name = "${local.name}-karpenter"
  role = aws_iam_role.karpenter_node_instance_profile.name

  tags = local.tags
}

# Karpenter SQS Queue for Spot Interruption
resource "aws_sqs_queue" "karpenter" {
  name = "${local.name}-karpenter"

  tags = local.tags
}

# SQS Queue Policy for Spot Interruption
resource "aws_sqs_queue_policy" "karpenter" {
  queue_url = aws_sqs_queue.karpenter.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Sid    = "EC2InterruptionPolicy"
        Effect = "Allow"
        Principal = {
          Service = ["events.amazonaws.com", "sqs.amazonaws.com"]
        }
        Action   = "sqs:SendMessage"
        Resource = aws_sqs_queue.karpenter.arn
      }
    ]
  })
}

# EventBridge Rule for Spot Interruption
resource "aws_cloudwatch_event_rule" "karpenter" {
  name        = "${local.name}-karpenter-spot-interruption"
  description = "Karpenter Spot Instance Interruption"

  event_pattern = jsonencode({
    source      = ["aws.ec2"]
    detail-type = ["EC2 Spot Instance Interruption Warning"]
  })

  tags = local.tags
}

resource "aws_cloudwatch_event_target" "karpenter" {
  rule      = aws_cloudwatch_event_rule.karpenter.name
  target_id = "KarpenterInterruptionQueueTarget"
  arn       = aws_sqs_queue.karpenter.arn
}

# AWS Load Balancer Controller IAM Role
resource "aws_iam_role" "aws_load_balancer_controller" {
  name = "${local.name}-aws-load-balancer-controller"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Principal = {
          Federated = module.eks.oidc_provider_arn
        }
        Condition = {
          StringEquals = {
            "${module.eks.oidc_provider}:sub" = "system:serviceaccount:kube-system:aws-load-balancer-controller"
            "${module.eks.oidc_provider}:aud" = "sts.amazonaws.com"
          }
        }
      }
    ]
  })

  tags = local.tags
}

resource "aws_iam_role_policy" "aws_load_balancer_controller" {
  name = "${local.name}-aws-load-balancer-controller"
  role = aws_iam_role.aws_load_balancer_controller.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "iam:CreateServiceLinkedRole",
          "ec2:DescribeAccountAttributes",
          "ec2:DescribeAddresses",
          "ec2:DescribeAvailabilityZones",
          "ec2:DescribeInternetGateways",
          "ec2:DescribeVpcs",
          "ec2:DescribeSubnets",
          "ec2:DescribeSecurityGroups",
          "ec2:DescribeInstances",
          "ec2:DescribeNetworkInterfaces",
          "ec2:DescribeTags",
          "ec2:GetCoipPoolUsage",
          "ec2:DescribeCoipPools",
          "elasticloadbalancing:DescribeLoadBalancers",
          "elasticloadbalancing:DescribeLoadBalancerAttributes",
          "elasticloadbalancing:DescribeListeners",
          "elasticloadbalancing:DescribeListenerCertificates",
          "elasticloadbalancing:DescribeSSLPolicies",
          "elasticloadbalancing:DescribeRules",
          "elasticloadbalancing:DescribeTargetGroups",
          "elasticloadbalancing:DescribeTargetGroupAttributes",
          "elasticloadbalancing:DescribeTargetHealth",
          "elasticloadbalancing:DescribeTags"
        ]
        Resource = "*"
      },
      {
        Effect = "Allow"
        Action = [
          "cognito-idp:DescribeUserPoolClient",
          "acm:ListCertificates",
          "acm:DescribeCertificate",
          "iam:ListServerCertificates",
          "iam:GetServerCertificate",
          "waf-regional:GetWebACL",
          "waf-regional:GetWebACLForResource",
          "waf-regional:AssociateWebACL",
          "waf-regional:DisassociateWebACL",
          "wafv2:GetWebACL",
          "wafv2:GetWebACLForResource",
          "wafv2:AssociateWebACL",
          "wafv2:DisassociateWebACL",
          "shield:DescribeProtection",
          "shield:GetSubscriptionState",
          "shield:DescribeSubscription",
          "shield:CreateProtection",
          "shield:DeleteProtection"
        ]
        Resource = "*"
      },
      {
        Effect = "Allow"
        Action = [
          "ec2:AuthorizeSecurityGroupIngress",
          "ec2:RevokeSecurityGroupIngress"
        ]
        Resource = "*"
      },
      {
        Effect = "Allow"
        Action = [
          "ec2:CreateSecurityGroup"
        ]
        Resource = "*"
      },
      {
        Effect = "Allow"
        Action = [
          "ec2:CreateTags"
        ]
        Resource = "arn:aws:ec2:*:*:security-group/*"
        Condition = {
          StringEquals = {
            "ec2:CreateAction" = "CreateSecurityGroup"
          }
          Null = {
            "aws:RequestedRegion" = "false"
          }
        }
      },
      {
        Effect = "Allow"
        Action = [
          "elasticloadbalancing:CreateLoadBalancer",
          "elasticloadbalancing:CreateTargetGroup"
        ]
        Resource = "*"
        Condition = {
          Null = {
            "aws:RequestedRegion" = "false"
          }
        }
      },
      {
        Effect = "Allow"
        Action = [
          "elasticloadbalancing:CreateListener",
          "elasticloadbalancing:DeleteListener",
          "elasticloadbalancing:CreateRule",
          "elasticloadbalancing:DeleteRule"
        ]
        Resource = "*"
      },
      {
        Effect = "Allow"
        Action = [
          "elasticloadbalancing:AddTags",
          "elasticloadbalancing:RemoveTags"
        ]
        Resource = [
          "arn:aws:elasticloadbalancing:*:*:targetgroup/*/*",
          "arn:aws:elasticloadbalancing:*:*:loadbalancer/net/*/*",
          "arn:aws:elasticloadbalancing:*:*:loadbalancer/app/*/*"
        ]
        Condition = {
          Null = {
            "aws:RequestedRegion"                   = "false",
            "aws:ResourceTag/elbv2.k8s.aws/cluster" = "false"
          }
        }
      },
      {
        Effect = "Allow"
        Action = [
          "elasticloadbalancing:ModifyLoadBalancerAttributes",
          "elasticloadbalancing:SetIpAddressType",
          "elasticloadbalancing:SetSecurityGroups",
          "elasticloadbalancing:SetSubnets",
          "elasticloadbalancing:DeleteLoadBalancer",
          "elasticloadbalancing:ModifyTargetGroup",
          "elasticloadbalancing:ModifyTargetGroupAttributes",
          "elasticloadbalancing:DeleteTargetGroup"
        ]
        Resource = "*"
        Condition = {
          Null = {
            "aws:ResourceTag/elbv2.k8s.aws/cluster" = "false"
          }
        }
      },
      {
        Effect = "Allow"
        Action = [
          "elasticloadbalancing:RegisterTargets",
          "elasticloadbalancing:DeregisterTargets"
        ]
        Resource = "arn:aws:elasticloadbalancing:*:*:targetgroup/*/*"
      }
    ]
  })
}

# External DNS IAM Role
resource "aws_iam_role" "external_dns" {
  name = "${local.name}-external-dns"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Principal = {
          Federated = module.eks.oidc_provider_arn
        }
        Condition = {
          StringEquals = {
            "${module.eks.oidc_provider}:sub" = "system:serviceaccount:external-dns:external-dns",
            "${module.eks.oidc_provider}:aud" = "sts.amazonaws.com"
          }
        }
      }
    ]
  })

  tags = local.tags
}

resource "aws_iam_role_policy" "external_dns" {
  name = "${local.name}-external-dns"
  role = aws_iam_role.external_dns.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "route53:ChangeResourceRecordSets"
        ]
        Resource = [
          "arn:aws:route53:::hostedzone/*"
        ]
      },
      {
        Effect = "Allow"
        Action = [
          "route53:ListHostedZones",
          "route53:ListResourceRecordSets"
        ]
        Resource = "*"
      }
    ]
  })
}

# Cert-Manager IAM Role
resource "aws_iam_role" "cert_manager" {
  name = "${local.name}-cert-manager"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Principal = {
          Federated = module.eks.oidc_provider_arn
        }
        Condition = {
          StringEquals = {
            "${module.eks.oidc_provider}:sub" = "system:serviceaccount:cert-manager:cert-manager",
            "${module.eks.oidc_provider}:aud" = "sts.amazonaws.com"
          }
        }
      }
    ]
  })

  tags = local.tags
}

resource "aws_iam_role_policy" "cert_manager" {
  name = "${local.name}-cert-manager"
  role = aws_iam_role.cert_manager.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "route53:GetChange"
        ]
        Resource = "arn:aws:route53:::change/*"
      },
      {
        Effect = "Allow"
        Action = [
          "route53:ChangeResourceRecordSets",
          "route53:ListResourceRecordSets"
        ]
        Resource = "arn:aws:route53:::hostedzone/*"
      },
      {
        Effect = "Allow"
        Action = [
          "route53:ListHostedZonesByName"
        ]
        Resource = "*"
      }
    ]
  })
}

# Secrets Store CSI Driver IAM Role
resource "aws_iam_role" "secrets_store_csi" {
  name = "${local.name}-secrets-store-csi"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Principal = {
          Federated = module.eks.oidc_provider_arn
        }
        Condition = {
          StringEquals = {
            "${module.eks.oidc_provider}:sub" = "system:serviceaccount:kube-system:secrets-store-csi-driver",
            "${module.eks.oidc_provider}:aud" = "sts.amazonaws.com"
          }
        }
      }
    ]
  })

  tags = local.tags
}

resource "aws_iam_role_policy" "secrets_store_csi" {
  name = "${local.name}-secrets-store-csi"
  role = aws_iam_role.secrets_store_csi.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "secretsmanager:GetSecretValue",
          "secretsmanager:DescribeSecret"
        ]
        Resource = "*"
      },
      {
        Effect = "Allow"
        Action = [
          "ssm:GetParameter",
          "ssm:GetParameters",
          "ssm:GetParametersByPath"
        ]
        Resource = "*"
      }
    ]
  })
}

# ArgoCD IAM Role
resource "aws_iam_role" "argocd" {
  name = "${local.name}-argocd"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Principal = {
          Federated = module.eks.oidc_provider_arn
        }
        Condition = {
          StringEquals = {
            "${module.eks.oidc_provider}:sub" = "system:serviceaccount:argocd:argocd-server",
            "${module.eks.oidc_provider}:aud" = "sts.amazonaws.com"
          }
        }
      }
    ]
  })

  tags = local.tags
}

resource "aws_iam_role_policy" "argocd" {
  name = "${local.name}-argocd"
  role = aws_iam_role.argocd.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "eks:DescribeCluster",
          "eks:ListClusters"
        ]
        Resource = "*"
      }
    ]
  })
}

# Crossplane IAM Role
resource "aws_iam_role" "crossplane" {
  name = "${local.name}-crossplane"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Principal = {
          Federated = module.eks.oidc_provider_arn
        }
        Condition = {
          StringEquals = {
            "${module.eks.oidc_provider}:sub" = "system:serviceaccount:crossplane-system:crossplane",
            "${module.eks.oidc_provider}:aud" = "sts.amazonaws.com"
          }
        }
      }
    ]
  })

  tags = local.tags
}

resource "aws_iam_role_policy" "crossplane" {
  name = "${local.name}-crossplane"
  role = aws_iam_role.crossplane.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "*"
        ]
        Resource = "*"
      }
    ]
  })
}

# Route53 Hosted Zone for External DNS
resource "aws_route53_zone" "main" {
  count = var.create_route53_zone ? 1 : 0
  name  = var.domain_name

  tags = local.tags
}

# ACM Certificate for Cert-Manager
resource "aws_acm_certificate" "main" {
  count             = var.create_acm_certificate ? 1 : 0
  domain_name       = var.domain_name
  validation_method = "DNS"

  subject_alternative_names = [
    "*.${var.domain_name}"
  ]

  lifecycle {
    create_before_destroy = true
  }

  tags = local.tags
}

resource "aws_acm_certificate_validation" "main" {
  count                   = var.create_acm_certificate ? 1 : 0
  certificate_arn         = aws_acm_certificate.main[0].arn
  validation_record_fqdns = [for record in aws_route53_record.cert_validation : record.fqdn]

  timeouts {
    create = "5m"
  }
}

# Serverless PostgreSQL for Backstage
resource "aws_rds_cluster" "backstage_postgres" {
  cluster_identifier           = "${local.name}-backstage-postgres"
  engine                       = "aurora-postgresql"
  engine_mode                  = "provisioned"
  engine_version               = "15.4"
  database_name                = "backstage"
  master_username              = "backstage"
  master_password              = random_password.backstage_postgres_password.result
  backup_retention_period      = 7
  preferred_backup_window      = "07:00-09:00"
  preferred_maintenance_window = "sun:09:00-sun:11:00"
  skip_final_snapshot          = true
  deletion_protection          = false

  serverlessv2_scaling_configuration {
    max_capacity = 16
    min_capacity = 0.5
  }

  vpc_security_group_ids = [aws_security_group.backstage_postgres.id]
  db_subnet_group_name   = aws_db_subnet_group.backstage_postgres.name

  tags = merge(local.tags, {
    Name = "${local.name}-backstage-postgres"
  })
}

# Aurora Serverless v2 instance
resource "aws_rds_cluster_instance" "backstage_postgres" {
  cluster_identifier = aws_rds_cluster.backstage_postgres.id
  instance_class     = "db.serverless"
  engine             = aws_rds_cluster.backstage_postgres.engine
  engine_version     = aws_rds_cluster.backstage_postgres.engine_version

  tags = merge(local.tags, {
    Name = "${local.name}-backstage-postgres-instance"
  })
}

# Random password for Backstage PostgreSQL
resource "random_password" "backstage_postgres_password" {
  length  = 32
  special = true
}

# Security group for Backstage PostgreSQL
resource "aws_security_group" "backstage_postgres" {
  name_prefix = "${local.name}-backstage-postgres-"
  vpc_id      = module.vpc.vpc_id

  ingress {
    from_port   = 5432
    to_port     = 5432
    protocol    = "tcp"
    cidr_blocks = [module.vpc.vpc_cidr_block]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = merge(local.tags, {
    Name = "${local.name}-backstage-postgres"
  })
}

# DB subnet group for Backstage PostgreSQL
resource "aws_db_subnet_group" "backstage_postgres" {
  name       = "${local.name}-backstage-postgres"
  subnet_ids = module.vpc.private_subnets

  tags = merge(local.tags, {
    Name = "${local.name}-backstage-postgres"
  })
}

resource "aws_route53_record" "cert_validation" {
  for_each = var.create_acm_certificate ? {
    for dvo in aws_acm_certificate.main[0].domain_validation_options : dvo.domain_name => {
      name   = dvo.resource_record_name
      record = dvo.resource_record_value
      type   = dvo.resource_record_type
    }
  } : {}

  allow_overwrite = true
  name            = each.value.name
  records         = [each.value.record]
  ttl             = 60
  type            = each.value.type
  zone_id         = aws_route53_zone.main[0].zone_id
}

#############################################
# Dedicated Helm release for Karpenter
#############################################
## Karpenter standalone Helm release removed; managed via Blueprints

#############################################
# Dedicated Helm release to install EC2NodeClass and NodePool (raw chart)
#############################################
resource "helm_release" "karpenter_config" {
  count      = 0
  name       = "karpenter-config"
  repository = "https://stevehipwell.github.io/helm-charts/"
  chart      = "raw"
  version    = "0.3.0"
  namespace  = "karpenter"

  values = [
    yamlencode({
      resources = [
        # EC2NodeClass default
        {
          apiVersion = "karpenter.k8s.aws/v1beta1"
          kind       = "EC2NodeClass"
          metadata = {
            name = "default"
          }
          spec = {
            role      = aws_iam_role.karpenter_node_instance_profile.name
            amiFamily = "AL2"
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
            subnetSelectorTerms = [
              { tags = { "karpenter.sh/discovery" = local.name } }
            ]
            securityGroupSelectorTerms = [
              { tags = { "kubernetes.io/cluster/${module.eks.cluster_name}" = "owned" } }
            ]
            metadataOptions = {
              httpEndpoint            = "enabled"
              httpProtocolIPv6        = "disabled"
              httpPutResponseHopLimit = 2
              httpTokens              = "required"
            }
          }
        },

        # NodePool cost-optimized (spot)
        {
          apiVersion = "karpenter.sh/v1beta1"
          kind       = "NodePool"
          metadata = {
            name = "cost-optimized"
          }
          spec = {
            template = {
              metadata = {
                labels = {
                  "node-type" = "cost-optimized"
                }
              }
              spec = {
                requirements = [
                  { key = "karpenter.sh/capacity-type", operator = "In", values = ["spot"] },
                  { key = "kubernetes.io/arch", operator = "In", values = ["arm64", "amd64"] },
                  { key = "node.kubernetes.io/instance-type", operator = "In", values = var.karpenter_instance_types }
                ]
                nodeClassRef = {
                  apiVersion = "karpenter.k8s.aws/v1beta1"
                  kind       = "EC2NodeClass"
                  name       = "default"
                }
              }
            }
            limits = { cpu = "1000", memory = "1000Gi" }
            disruption = {
              consolidationPolicy = "WhenEmpty"
              consolidateAfter    = "30s"
            }
          }
        }
      ]
    })
  ]

  depends_on = [
    module.eks_blueprints_addons
  ]
}
