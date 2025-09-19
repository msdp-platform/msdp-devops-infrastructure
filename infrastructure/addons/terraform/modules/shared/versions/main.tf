# Shared Version Management
# Centralized version management for all infrastructure components

locals {
  # Terraform Provider Versions
  provider_versions = {
    terraform      = "~> 1.9"
    helm          = "~> 2.15"
    kubernetes    = "~> 2.24"
    azurerm       = "~> 3.0"
    aws           = "~> 5.0"
    kubectl       = "~> 1.14"
    random        = "~> 3.4"
    tls           = "~> 4.0"
  }
  
  # Kubernetes Versions
  kubernetes_versions = {
    default       = "1.29.7"
    supported     = ["1.28.5", "1.29.7", "1.30.3"]
    addon_compat  = "1.29"
  }
  
  # Tool Versions
  tool_versions = {
    terraform     = "1.9.5"
    kubectl       = "1.28.0"
    helm          = "3.12.0"
    python        = "3.11"
    node          = "18"
    docker        = "24.0"
  }
  
  # GitHub Actions Versions
  github_actions = {
    checkout           = "v4"
    setup_terraform    = "v3"
    setup_python       = "v4"
    setup_node         = "v4"
    cache             = "v3"
    upload_artifact   = "v4"
    download_artifact = "v4"
  }
  # Container image versions
  image_versions = {
    # Cert-Manager
    cert_manager = {
      controller = "v1.13.2"
      webhook    = "v1.13.2"
      cainjector = "v1.13.2"
      ctl        = "v1.13.2"
    }
    
    # External DNS
    external_dns = "v0.14.0"
    
    # NGINX Ingress
    nginx_ingress = {
      controller = "v1.8.2"
      webhook    = "v20230407"
    }
    
    # ArgoCD
    argocd = "v2.8.4"
    
    # Prometheus Stack
    prometheus = {
      operator          = "v0.68.0"
      prometheus        = "v2.46.0"
      alertmanager      = "v0.25.0"
      node_exporter     = "v1.6.1"
      kube_state_metrics = "v2.10.0"
      grafana           = "10.1.1"
    }
    
    # Karpenter
    karpenter = "v0.31.0"
    
    # KEDA
    keda = {
      keda           = "2.11.2"
      metrics_server = "2.11.2"
      webhooks       = "2.11.2"
    }
  }
  
  # Helm chart versions
  chart_versions = {
    cert_manager      = "v1.13.2"
    external_dns      = "1.13.1"
    nginx_ingress     = "4.11.3"
    argocd           = "5.51.3"
    prometheus_stack  = "65.5.1"
    karpenter        = "v0.32.1"
    keda             = "2.12.1"
    crossplane       = "2.0.2"
    backstage        = "2.6.1"
    azure_disk_csi   = "v1.29.2"
  }
  
  # Repository URLs
  helm_repositories = {
    jetstack           = "https://charts.jetstack.io"
    external_dns       = "https://kubernetes-sigs.github.io/external-dns/"
    nginx_ingress      = "https://kubernetes.github.io/ingress-nginx"
    argocd            = "https://argoproj.github.io/argo-helm"
    prometheus        = "https://prometheus-community.github.io/helm-charts"
    karpenter         = "oci://public.ecr.aws/karpenter"
    keda              = "https://kedacore.github.io/charts"
    crossplane        = "https://charts.crossplane.io/stable"
    backstage         = "https://backstage.github.io/charts"
  }
}
