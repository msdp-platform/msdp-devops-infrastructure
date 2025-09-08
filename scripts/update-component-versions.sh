#!/bin/bash

# Dynamic Component Version Update Script
# This script reads from global.yaml and environment configs to dynamically update component versions

set -e

# Load configuration
source scripts/load-config-robust.sh
load_global_config

# Function to update Helm values file
update_helm_values() {
    local component="$1"
    local values_file="$2"
    local version_key="$3"
    local version_value="$4"
    
    echo "🔧 Updating $component version to $version_value in $values_file"
    
    # Use yq to update the version in the Helm values file
    yq eval "$version_key = \"$version_value\"" -i "$values_file"
    
    echo "✅ Updated $component version in $values_file"
}

# Function to update Kustomization file
update_kustomization() {
    local component="$1"
    local kustomization_file="$2"
    local version_key="$3"
    local version_value="$4"
    
    echo "🔧 Updating $component chart version to $version_value in $kustomization_file"
    
    # Use yq to update the version in the Kustomization file
    yq eval "$version_key = \"$version_value\"" -i "$kustomization_file"
    
    echo "✅ Updated $component chart version in $kustomization_file"
}

# Function to update deployment image
update_deployment_image() {
    local component="$1"
    local deployment_file="$2"
    local image_value="$3"
    
    echo "🔧 Updating $component image to $image_value in $deployment_file"
    
    # Use yq to update the image in the deployment file
    yq eval ".spec.template.spec.containers[0].image = \"$image_value\"" -i "$deployment_file"
    
    echo "✅ Updated $component image in $deployment_file"
}

echo "🚀 Starting dynamic component version updates..."

# Update ArgoCD
ARGOCD_VERSION=$(get_config_value "applications.argocd.version")
ARGOCD_IMAGE=$(get_config_value "applications.argocd.image")
ARGOCD_CHART_VERSION=$(get_config_value "applications.argocd.chart_version")

echo "📋 ArgoCD Configuration:"
echo "  Version: $ARGOCD_VERSION"
echo "  Image: $ARGOCD_IMAGE"
echo "  Chart Version: $ARGOCD_CHART_VERSION"

update_helm_values "ArgoCD" "infrastructure/applications/argocd/helm-values.yaml" ".argo-cd.image.tag" "$ARGOCD_VERSION"
update_kustomization "ArgoCD" "infrastructure/applications/argocd/kustomization.yaml" ".helmCharts[0].version" "$ARGOCD_CHART_VERSION"

# Update Backstage
BACKSTAGE_VERSION=$(get_config_value "applications.backstage.version")
BACKSTAGE_IMAGE=$(get_config_value "applications.backstage.image")

echo "📋 Backstage Configuration:"
echo "  Version: $BACKSTAGE_VERSION"
echo "  Image: $BACKSTAGE_IMAGE"

BACKSTAGE_FULL_IMAGE="${BACKSTAGE_IMAGE}:${BACKSTAGE_VERSION}"
update_deployment_image "Backstage" "infrastructure/applications/backstage/deployment.yaml" "$BACKSTAGE_FULL_IMAGE"

# Update Crossplane
CROSSPLANE_VERSION=$(get_config_value "applications.crossplane.version")
CROSSPLANE_CHART_VERSION=$(get_config_value "applications.crossplane.chart_version")

echo "📋 Crossplane Configuration:"
echo "  Version: $CROSSPLANE_VERSION"
echo "  Chart Version: $CROSSPLANE_CHART_VERSION"

update_kustomization "Crossplane" "infrastructure/applications/crossplane/kustomization.yaml" ".helmCharts[0].version" "$CROSSPLANE_CHART_VERSION"

# Update Platform Components
echo "🔧 Updating platform components..."

# NGINX Ingress
NGINX_VERSION=$(get_config_value "platform_components.nginx_ingress.version")
NGINX_CHART_VERSION=$(get_config_value "platform_components.nginx_ingress.chart_version")

echo "📋 NGINX Ingress Configuration:"
echo "  Version: $NGINX_VERSION"
echo "  Chart Version: $NGINX_CHART_VERSION"

update_helm_values "NGINX Ingress" "infrastructure/platforms/networking/nginx-ingress/helm-values.yaml" ".controller.image.tag" "$NGINX_VERSION"
update_kustomization "NGINX Ingress" "infrastructure/platforms/networking/nginx-ingress/kustomization.yaml" ".helmCharts[0].version" "$NGINX_CHART_VERSION"

# Cert-Manager
CERT_MANAGER_VERSION=$(get_config_value "platform_components.cert_manager.version")
CERT_MANAGER_CHART_VERSION=$(get_config_value "platform_components.cert_manager.chart_version")

echo "📋 Cert-Manager Configuration:"
echo "  Version: $CERT_MANAGER_VERSION"
echo "  Chart Version: $CERT_MANAGER_CHART_VERSION"

update_helm_values "Cert-Manager" "infrastructure/platforms/networking/cert-manager/helm-values.yaml" ".image.tag" "$CERT_MANAGER_VERSION"
update_helm_values "Cert-Manager" "infrastructure/platforms/networking/cert-manager/helm-values.yaml" ".webhook.image.tag" "$CERT_MANAGER_VERSION"
update_helm_values "Cert-Manager" "infrastructure/platforms/networking/cert-manager/helm-values.yaml" ".cainjector.image.tag" "$CERT_MANAGER_VERSION"
update_kustomization "Cert-Manager" "infrastructure/platforms/networking/cert-manager/kustomization.yaml" ".helmCharts[0].version" "$CERT_MANAGER_CHART_VERSION"

# External DNS (uses direct Kubernetes manifests, not Helm)
EXTERNAL_DNS_VERSION=$(get_config_value "platform_components.external_dns.version")

echo "📋 External DNS Configuration:"
echo "  Version: $EXTERNAL_DNS_VERSION"

# External DNS uses direct deployment, update the deployment file
update_deployment_image "External DNS" "infrastructure/platforms/networking/external-dns/deployment.yaml" "registry.k8s.io/external-dns/external-dns:$EXTERNAL_DNS_VERSION"

# Prometheus
PROMETHEUS_VERSION=$(get_config_value "platform_components.prometheus.version")
PROMETHEUS_CHART_VERSION=$(get_config_value "platform_components.prometheus.chart_version")

echo "📋 Prometheus Configuration:"
echo "  Version: $PROMETHEUS_VERSION"
echo "  Chart Version: $PROMETHEUS_CHART_VERSION"

update_kustomization "Prometheus" "infrastructure/platforms/monitoring/prometheus/kustomization.yaml" ".helmCharts[0].version" "$PROMETHEUS_CHART_VERSION"

# Grafana
GRAFANA_VERSION=$(get_config_value "platform_components.grafana.version")
GRAFANA_CHART_VERSION=$(get_config_value "platform_components.grafana.chart_version")

echo "📋 Grafana Configuration:"
echo "  Version: $GRAFANA_VERSION"
echo "  Chart Version: $GRAFANA_CHART_VERSION"

update_helm_values "Grafana" "infrastructure/platforms/monitoring/grafana/helm-values.yaml" ".image.tag" "$GRAFANA_VERSION"
update_kustomization "Grafana" "infrastructure/platforms/monitoring/grafana/kustomization.yaml" ".helmCharts[0].version" "$GRAFANA_CHART_VERSION"

echo "✅ All component versions updated dynamically from configuration!"
echo "📊 Summary of updates:"
echo "  - ArgoCD: $ARGOCD_VERSION (chart: $ARGOCD_CHART_VERSION)"
echo "  - Backstage: $BACKSTAGE_VERSION"
echo "  - Crossplane: $CROSSPLANE_CHART_VERSION"
echo "  - NGINX Ingress: $NGINX_VERSION (chart: $NGINX_CHART_VERSION)"
echo "  - Cert-Manager: $CERT_MANAGER_VERSION (chart: $CERT_MANAGER_CHART_VERSION)"
echo "  - External DNS: $EXTERNAL_DNS_VERSION"
echo "  - Prometheus: $PROMETHEUS_CHART_VERSION"
echo "  - Grafana: $GRAFANA_VERSION (chart: $GRAFANA_CHART_VERSION)"
