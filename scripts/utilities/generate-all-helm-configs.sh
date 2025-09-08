#!/bin/bash

# Generate all Helm-based component configurations from global.yaml
# This eliminates hardcoded values and ensures consistency across all components

set -euo pipefail

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Function to print colored output
print_status() {
    echo -e "${GREEN}[INFO]${NC} $1"
}

print_warning() {
    echo -e "${YELLOW}[WARN]${NC} $1"
}

print_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

print_component() {
    echo -e "${BLUE}[COMPONENT]${NC} $1"
}

# Check if yq is installed
if ! command -v yq &> /dev/null; then
    print_error "yq is not installed. Please install yq first."
    exit 1
fi

# Paths
GLOBAL_CONFIG="infrastructure/config/global.yaml"
ENVIRONMENT_CONFIG="infrastructure/config/environments/dev.yaml"

print_status "Generating all Helm component configurations from global.yaml..."

# Extract environment-specific values
ENVIRONMENT=$(yq eval '.environment' "$ENVIRONMENT_CONFIG")
CLUSTER_DOMAIN=$(yq eval '.domains.base' "$GLOBAL_CONFIG")

print_status "Environment: $ENVIRONMENT, Domain: $CLUSTER_DOMAIN"

# Function to generate kustomization.yaml for a component
generate_kustomization() {
    local component_name="$1"
    local component_type="$2"  # "platform_components" or "applications"
    local kustomization_path="$3"
    local chart_name="$4"
    local release_name="$5"
    local namespace="$6"
    local values_file="$7"
    
    print_component "Generating kustomization.yaml for $component_name..."
    
    # Extract values from global.yaml
    local version=$(yq eval ".${component_type}.${component_name}.version" "$GLOBAL_CONFIG")
    local chart_version=$(yq eval ".${component_type}.${component_name}.chart_version" "$GLOBAL_CONFIG")
    local helm_repo=$(yq eval ".helm_repos.${component_name//-/_}" "$GLOBAL_CONFIG")
    
    # Create backup if file exists
    if [ -f "$kustomization_path" ]; then
        cp "$kustomization_path" "${kustomization_path}.backup.$(date +%Y%m%d_%H%M%S)"
        print_warning "Backed up existing kustomization.yaml"
    fi
    
    # Generate kustomization.yaml
    cat > "$kustomization_path" << EOF
apiVersion: kustomize.config.k8s.io/v1beta1
kind: Kustomization
metadata:
  name: $component_name
  annotations:
    config.kubernetes.io/local-config: "true"
resources:
  - namespace.yaml
# Helm chart configuration
helmCharts:
  - name: $chart_name
    repo: $helm_repo
    version: $chart_version
    releaseName: $release_name
    namespace: $namespace
    valuesFile: $values_file
namespace: $namespace
EOF
    
    print_status "Generated kustomization.yaml for $component_name (version: $chart_version)"
}

# Function to generate helm-values.yaml for a component
generate_helm_values() {
    local component_name="$1"
    local component_type="$2"
    local values_path="$3"
    local hostname="$4"
    
    print_component "Generating helm-values.yaml for $component_name..."
    
    # Extract values from global.yaml
    local version=$(yq eval ".${component_type}.${component_name}.version" "$GLOBAL_CONFIG")
    local image=$(yq eval ".${component_type}.${component_name}.image" "$GLOBAL_CONFIG")
    local chart_version=$(yq eval ".${component_type}.${component_name}.chart_version" "$GLOBAL_CONFIG")
    
    # Create backup if file exists
    if [ -f "$values_path" ]; then
        cp "$values_path" "${values_path}.backup.$(date +%Y%m%d_%H%M%S)"
        print_warning "Backed up existing helm-values.yaml"
    fi
    
    # Generate component-specific helm-values.yaml
    case "$component_name" in
        "argocd")
            generate_argocd_values "$values_path" "$version" "$image" "$chart_version" "$hostname"
            ;;
        "grafana")
            generate_grafana_values "$values_path" "$version" "$image" "$chart_version" "$hostname"
            ;;
        "prometheus")
            generate_prometheus_values "$values_path" "$version" "$image" "$chart_version" "$hostname"
            ;;
        "cert_manager")
            generate_cert_manager_values "$values_path" "$version" "$image" "$chart_version"
            ;;
        "nginx_ingress")
            generate_nginx_ingress_values "$values_path" "$version" "$image" "$chart_version"
            ;;
        "crossplane")
            generate_crossplane_values "$values_path" "$version" "$image" "$chart_version"
            ;;
        *)
            print_warning "No specific template for $component_name, creating basic template"
            generate_basic_values "$values_path" "$version" "$image" "$chart_version"
            ;;
    esac
    
    print_status "Generated helm-values.yaml for $component_name"
}

# Generate ArgoCD specific values
generate_argocd_values() {
    local values_path="$1"
    local version="$2"
    local image="$3"
    local chart_version="$4"
    local hostname="$5"
    
    cat > "$values_path" << EOF
# ArgoCD Helm Values
# Generated from global.yaml - DO NOT EDIT MANUALLY
# Chart Version: $chart_version
# ArgoCD Version: $version

# Global configuration
global:
  imageRegistry: ""

# ArgoCD configuration
argo-cd:
  # Image configuration
  image:
    repository: $image
    tag: "$version"
    pullPolicy: IfNotPresent

  # Server configuration
  server:
    # Service configuration
    service:
      type: ClusterIP
      port: 80
      targetPort: 8080
    
    # Ingress configuration (disabled - using separate ingress.yaml)
    ingress:
      enabled: false

    # Additional server configuration
    extraArgs:
      - --insecure
      - --rootpath=/argocd

  # Application Controller configuration
  controller:
    replicas: 1
    resources:
      limits:
        cpu: 1000m
        memory: 1Gi
      requests:
        cpu: 100m
        memory: 128Mi

  # Repository Server configuration
  repoServer:
    replicas: 1
    resources:
      limits:
        cpu: 1000m
        memory: 1Gi
      requests:
        cpu: 100m
        memory: 128Mi

  # Redis configuration
  redis:
    enabled: true
    resources:
      limits:
        cpu: 100m
        memory: 128Mi
      requests:
        cpu: 50m
        memory: 64Mi

  # Dex configuration (disabled for simplicity)
  dex:
    enabled: false

  # Notifications configuration
  notifications:
    enabled: true
    resources:
      limits:
        cpu: 100m
        memory: 128Mi
      requests:
        cpu: 50m
        memory: 64Mi

  # ApplicationSet configuration
  applicationSet:
    enabled: true
    resources:
      limits:
        cpu: 100m
        memory: 128Mi
      requests:
        cpu: 50m
        memory: 64Mi

# ConfigMap configuration
configs:
  cm:
    url: "https://$hostname"
    application.instanceLabelKey: "argocd.argoproj.io/instance"
    server.rbac.log.enforce.enable: "false"
    timeout.hard.reconciliation: "0s"
    timeout.reconciliation: "180s"
    admin.enabled: "true"
    exec.enabled: "false"

# RBAC configuration
configs:
  rbac:
    policy.default: role:readonly
    policy.csv: |
      p, role:admin, applications, *, */*, allow
      p, role:admin, clusters, *, *, allow
      p, role:admin, repositories, *, *, allow
      g, argocd-admins, role:admin
EOF
}

# Generate Grafana specific values
generate_grafana_values() {
    local values_path="$1"
    local version="$2"
    local image="$3"
    local chart_version="$4"
    local hostname="$5"
    
    cat > "$values_path" << EOF
# Grafana Helm Values
# Generated from global.yaml - DO NOT EDIT MANUALLY
# Chart Version: $chart_version
# Grafana Version: $version

# Image configuration
image:
  repository: $image
  tag: "$version"
  pullPolicy: IfNotPresent

# Service configuration
service:
  type: ClusterIP
  port: 80
  targetPort: 3000

# Ingress configuration
ingress:
  enabled: true
  ingressClassName: "nginx"
  annotations:
    cert-manager.io/cluster-issuer: "letsencrypt-prod"
    nginx.ingress.kubernetes.io/ssl-redirect: "true"
  hosts:
    - $hostname
  tls:
    - secretName: grafana-tls
      hosts:
        - $hostname

# Persistence configuration
persistence:
  enabled: true
  storageClassName: "default"
  accessModes:
    - ReadWriteOnce
  size: 10Gi

# Resources
resources:
  limits:
    cpu: 1000m
    memory: 2Gi
  requests:
    cpu: 200m
    memory: 512Mi

# Admin configuration
admin:
  existingSecret: "grafana-admin-secret"
  userKey: admin-user
  passwordKey: admin-password

# Grafana configuration
grafana.ini:
  server:
    root_url: "https://$hostname"
  security:
    allow_embedding: true
  auth.anonymous:
    enabled: false
EOF
}

# Generate Prometheus specific values
generate_prometheus_values() {
    local values_path="$1"
    local version="$2"
    local image="$3"
    local chart_version="$4"
    local hostname="$5"
    
    cat > "$values_path" << EOF
# Prometheus Helm Values
# Generated from global.yaml - DO NOT EDIT MANUALLY
# Chart Version: $chart_version
# Prometheus Version: $version

# Prometheus configuration
prometheus:
  prometheusSpec:
    image:
      repository: $image
      tag: "$version"
    
    # Resources
    resources:
      limits:
        cpu: 1500m
        memory: 3Gi
      requests:
        cpu: 300m
        memory: 1Gi
    
    # Storage
    storageSpec:
      volumeClaimTemplate:
        spec:
          storageClassName: "default"
          accessModes: ["ReadWriteOnce"]
          resources:
            requests:
              storage: 50Gi
    
    # Retention
    retention: "30d"
    
    # Service monitors
    serviceMonitorSelectorNilUsesHelmValues: false
    serviceMonitorSelector: {}
    serviceMonitorNamespaceSelector: {}

# Alertmanager configuration
alertmanager:
  alertmanagerSpec:
    resources:
      limits:
        cpu: 100m
        memory: 128Mi
      requests:
        cpu: 50m
        memory: 64Mi

# Grafana configuration (if included)
grafana:
  enabled: false  # We have separate Grafana deployment

# Node exporter
nodeExporter:
  enabled: true

# Kube state metrics
kubeStateMetrics:
  enabled: true
EOF
}

# Generate Cert-Manager specific values
generate_cert_manager_values() {
    local values_path="$1"
    local version="$2"
    local image="$3"
    local chart_version="$4"
    
    cat > "$values_path" << EOF
# Cert-Manager Helm Values
# Generated from global.yaml - DO NOT EDIT MANUALLY
# Chart Version: $chart_version
# Cert-Manager Version: $version

# Image configuration
image:
  repository: $image
  tag: "$version"
  pullPolicy: IfNotPresent

# Resources
resources:
  limits:
    cpu: 100m
    memory: 128Mi
  requests:
    cpu: 50m
    memory: 64Mi

# Webhook configuration
webhook:
  resources:
    limits:
      cpu: 100m
      memory: 128Mi
    requests:
      cpu: 50m
      memory: 64Mi

# CA injector configuration
cainjector:
  resources:
    limits:
      cpu: 100m
      memory: 128Mi
    requests:
      cpu: 50m
      memory: 64Mi

# Install CRDs
installCRDs: true
EOF
}

# Generate NGINX Ingress specific values
generate_nginx_ingress_values() {
    local values_path="$1"
    local version="$2"
    local image="$3"
    local chart_version="$4"
    
    cat > "$values_path" << EOF
# NGINX Ingress Helm Values
# Generated from global.yaml - DO NOT EDIT MANUALLY
# Chart Version: $chart_version
# NGINX Ingress Version: $version

# Controller configuration
controller:
  image:
    repository: registry.k8s.io/ingress-nginx/controller
    tag: "v$version"
    pullPolicy: IfNotPresent
  
  # Service configuration
  service:
    type: LoadBalancer
    externalTrafficPolicy: Local
  
  # Resources
  resources:
    limits:
      cpu: 500m
      memory: 512Mi
    requests:
      cpu: 100m
      memory: 128Mi
  
  # Config
  config:
    use-forwarded-headers: "true"
    compute-full-forwarded-for: "true"
    use-proxy-protocol: "false"

# Default backend
defaultBackend:
  enabled: true
  image:
    repository: registry.k8s.io/ingress-nginx/defaultbackend-amd64
    tag: "1.5"
  
  resources:
    limits:
      cpu: 10m
      memory: 20Mi
    requests:
      cpu: 10m
      memory: 20Mi
EOF
}

# Generate Crossplane specific values
generate_crossplane_values() {
    local values_path="$1"
    local version="$2"
    local image="$3"
    local chart_version="$4"
    
    cat > "$values_path" << EOF
# Crossplane Helm Values
# Generated from global.yaml - DO NOT EDIT MANUALLY
# Chart Version: $chart_version
# Crossplane Version: $version

# Image configuration
image:
  repository: $image
  tag: "$version"
  pullPolicy: IfNotPresent

# Resources
resources:
  limits:
    cpu: 1000m
    memory: 1Gi
  requests:
    cpu: 100m
    memory: 128Mi

# Install CRDs
installCRDs: true

# RBAC
rbac:
  create: true

# Service account
serviceAccount:
  create: true
  name: crossplane
EOF
}

# Generate basic values template
generate_basic_values() {
    local values_path="$1"
    local version="$2"
    local image="$3"
    local chart_version="$4"
    
    cat > "$values_path" << EOF
# Helm Values
# Generated from global.yaml - DO NOT EDIT MANUALLY
# Chart Version: $chart_version
# Version: $version

# Image configuration
image:
  repository: $image
  tag: "$version"
  pullPolicy: IfNotPresent

# Resources
resources:
  limits:
    cpu: 100m
    memory: 128Mi
  requests:
    cpu: 50m
    memory: 64Mi
EOF
}

# Generate all component configurations
print_status "Generating configurations for all Helm components..."

# Platform Components
generate_kustomization "nginx_ingress" "platform_components" "infrastructure/platforms/networking/nginx-ingress/kustomization.yaml" "ingress-nginx" "ingress-nginx" "ingress-nginx" "helm-values.yaml"
generate_helm_values "nginx_ingress" "platform_components" "infrastructure/platforms/networking/nginx-ingress/helm-values.yaml" ""

generate_kustomization "cert_manager" "platform_components" "infrastructure/platforms/networking/cert-manager/kustomization.yaml" "cert-manager" "cert-manager" "cert-manager" "helm-values.yaml"
generate_helm_values "cert_manager" "platform_components" "infrastructure/platforms/networking/cert-manager/helm-values.yaml" ""

generate_kustomization "grafana" "platform_components" "infrastructure/platforms/monitoring/grafana/kustomization.yaml" "grafana" "grafana" "monitoring" "helm-values.yaml"
generate_helm_values "grafana" "platform_components" "infrastructure/platforms/monitoring/grafana/helm-values.yaml" "grafana.${ENVIRONMENT}.${CLUSTER_DOMAIN}"

generate_kustomization "prometheus" "platform_components" "infrastructure/platforms/monitoring/prometheus/kustomization.yaml" "prometheus" "prometheus" "monitoring" "helm-values.yaml"
generate_helm_values "prometheus" "platform_components" "infrastructure/platforms/monitoring/prometheus/helm-values.yaml" "prometheus.${ENVIRONMENT}.${CLUSTER_DOMAIN}"

# Applications
generate_kustomization "argocd" "applications" "infrastructure/applications/argocd/kustomization.yaml" "argo-cd" "argocd" "argocd" "helm-values.yaml"
generate_helm_values "argocd" "applications" "infrastructure/applications/argocd/helm-values.yaml" "argocd.${ENVIRONMENT}.${CLUSTER_DOMAIN}"

generate_kustomization "crossplane" "applications" "infrastructure/applications/crossplane/kustomization.yaml" "crossplane" "crossplane" "crossplane-system" "helm-values.yaml"
generate_helm_values "crossplane" "applications" "infrastructure/applications/crossplane/helm-values.yaml" ""

print_status "All Helm component configurations generated successfully!"
print_status "Generated files:"
echo "  📦 Platform Components:"
echo "    - NGINX Ingress: kustomization.yaml + helm-values.yaml"
echo "    - Cert-Manager: kustomization.yaml + helm-values.yaml"
echo "    - Grafana: kustomization.yaml + helm-values.yaml"
echo "    - Prometheus: kustomization.yaml + helm-values.yaml"
echo "  📦 Applications:"
echo "    - ArgoCD: kustomization.yaml + helm-values.yaml"
echo "    - Crossplane: kustomization.yaml + helm-values.yaml"

print_status "Configuration generation completed!"
