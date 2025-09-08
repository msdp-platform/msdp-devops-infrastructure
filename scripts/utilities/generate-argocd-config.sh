#!/bin/bash

# Generate ArgoCD configuration files from global.yaml
# This eliminates hardcoded values and ensures consistency

set -euo pipefail

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
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

# Check if yq is installed
if ! command -v yq &> /dev/null; then
    print_error "yq is not installed. Please install yq first."
    exit 1
fi

# Paths
GLOBAL_CONFIG="infrastructure/config/global.yaml"
ENVIRONMENT_CONFIG="infrastructure/config/environments/dev.yaml"
HELM_VALUES="infrastructure/applications/argocd/helm-values.yaml"
KUSTOMIZATION="infrastructure/applications/argocd/kustomization.yaml"
TEMP_HELM_VALUES="/tmp/argocd-helm-values.yaml"
TEMP_KUSTOMIZATION="/tmp/argocd-kustomization.yaml"

print_status "Generating ArgoCD configuration from global.yaml..."

# Extract values from global.yaml
ARGOCD_VERSION=$(yq eval '.applications.argocd.version' "$GLOBAL_CONFIG")
ARGOCD_IMAGE=$(yq eval '.applications.argocd.image' "$GLOBAL_CONFIG")
ARGOCD_CHART_VERSION=$(yq eval '.applications.argocd.chart_version' "$GLOBAL_CONFIG")
ARGOCD_NAMESPACE=$(yq eval '.applications.argocd.namespace' "$GLOBAL_CONFIG")

# Extract environment-specific values
ENVIRONMENT=$(yq eval '.environment' "$ENVIRONMENT_CONFIG")
CLUSTER_DOMAIN=$(yq eval '.domains.base' "$GLOBAL_CONFIG")
ARGOCD_HOSTNAME="argocd.${ENVIRONMENT}.${CLUSTER_DOMAIN}"

print_status "Extracted values:"
echo "  - ArgoCD Version: $ARGOCD_VERSION"
echo "  - ArgoCD Image: $ARGOCD_IMAGE"
echo "  - Chart Version: $ARGOCD_CHART_VERSION"
echo "  - Namespace: $ARGOCD_NAMESPACE"
echo "  - Hostname: $ARGOCD_HOSTNAME"

# Generate helm-values.yaml
print_status "Generating helm-values.yaml..."
cat > "$TEMP_HELM_VALUES" << EOF
# ArgoCD Helm Values
# Generated from global.yaml - DO NOT EDIT MANUALLY
# Chart Version: $ARGOCD_CHART_VERSION
# ArgoCD Version: $ARGOCD_VERSION

# Global configuration
global:
  imageRegistry: ""

# ArgoCD configuration
argo-cd:
  # Image configuration
  image:
    repository: $ARGOCD_IMAGE
    tag: "$ARGOCD_VERSION"
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
    url: "https://$ARGOCD_HOSTNAME"
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

# Generate kustomization.yaml
print_status "Generating kustomization.yaml..."
cat > "$TEMP_KUSTOMIZATION" << EOF
apiVersion: kustomize.config.k8s.io/v1beta1
kind: Kustomization
metadata:
  name: argocd
  annotations:
    config.kubernetes.io/local-config: "true"
resources: []
# Helm chart configuration
helmCharts:
  - name: argo-cd
    repo: https://argoproj.github.io/argo-helm
    version: $ARGOCD_CHART_VERSION
    releaseName: argocd
    namespace: $ARGOCD_NAMESPACE
    valuesFile: helm-values.yaml
namespace: $ARGOCD_NAMESPACE
EOF

# Backup existing files
if [ -f "$HELM_VALUES" ]; then
    cp "$HELM_VALUES" "${HELM_VALUES}.backup.$(date +%Y%m%d_%H%M%S)"
    print_warning "Backed up existing helm-values.yaml"
fi

if [ -f "$KUSTOMIZATION" ]; then
    cp "$KUSTOMIZATION" "${KUSTOMIZATION}.backup.$(date +%Y%m%d_%H%M%S)"
    print_warning "Backed up existing kustomization.yaml"
fi

# Replace files
mv "$TEMP_HELM_VALUES" "$HELM_VALUES"
mv "$TEMP_KUSTOMIZATION" "$KUSTOMIZATION"

print_status "Configuration files generated successfully!"
print_status "Files updated:"
echo "  - $HELM_VALUES"
echo "  - $KUSTOMIZATION"

# Show diff if files existed before
if [ -f "${HELM_VALUES}.backup.$(date +%Y%m%d_%H%M%S)" ]; then
    print_status "Showing diff for helm-values.yaml:"
    diff -u "${HELM_VALUES}.backup.$(date +%Y%m%d_%H%M%S)" "$HELM_VALUES" || true
fi

print_status "ArgoCD configuration generation completed!"
