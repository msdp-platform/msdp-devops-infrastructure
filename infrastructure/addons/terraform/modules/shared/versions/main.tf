# Shared Version Management
# Centralized version management for all Kubernetes addons

locals {
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
