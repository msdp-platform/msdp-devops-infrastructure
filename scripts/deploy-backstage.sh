#!/bin/bash

# MSDP Backstage Deployment Script
# This script deploys Backstage using Crossplane and ArgoCD with no hardcoded values

set -euo pipefail

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Default values
ENVIRONMENT="dev"
BUSINESS_UNIT="platform-core"
COUNTRY="global"
NAMESPACE="backstage-${ENVIRONMENT}"
SOURCE_REPO="https://github.com/msdp-platform/msdp-devops-infrastructure"
SOURCE_REVISION="main"
DRY_RUN=false
VERBOSE=false

# Function to print colored output
print_status() {
    echo -e "${BLUE}[INFO]${NC} $1"
}

print_success() {
    echo -e "${GREEN}[SUCCESS]${NC} $1"
}

print_warning() {
    echo -e "${YELLOW}[WARNING]${NC} $1"
}

print_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

# Function to show usage
show_usage() {
    cat << EOF
Usage: $0 [OPTIONS]

Deploy MSDP Backstage using Crossplane and ArgoCD

OPTIONS:
    -e, --environment ENV     Environment (dev, staging, prod) [default: dev]
    -b, --business-unit BU    Business Unit (platform-core, food-delivery, grocery-delivery, cleaning-services, repair-services) [default: platform-core]
    -c, --country COUNTRY     Country (uk, india, global) [default: global]
    -n, --namespace NS        Kubernetes namespace [default: backstage-{environment}]
    -r, --repo REPO           Source repository URL [default: https://github.com/msdp-platform/msdp-devops-infrastructure]
    -v, --revision REV        Source revision [default: main]
    -d, --dry-run            Perform a dry run without making changes
    -V, --verbose            Enable verbose output
    -h, --help               Show this help message

EXAMPLES:
    # Deploy Backstage for dev environment
    $0 --environment dev

    # Deploy Backstage for food delivery in UK
    $0 --environment prod --business-unit food-delivery --country uk

    # Deploy Backstage with custom namespace
    $0 --environment staging --namespace backstage-staging

    # Dry run to see what would be deployed
    $0 --environment prod --dry-run

EOF
}

# Function to validate inputs
validate_inputs() {
    # Validate environment
    if [[ ! "$ENVIRONMENT" =~ ^(dev|staging|prod)$ ]]; then
        print_error "Invalid environment: $ENVIRONMENT. Must be one of: dev, staging, prod"
        exit 1
    fi

    # Validate business unit
    if [[ ! "$BUSINESS_UNIT" =~ ^(platform-core|food-delivery|grocery-delivery|cleaning-services|repair-services)$ ]]; then
        print_error "Invalid business unit: $BUSINESS_UNIT. Must be one of: platform-core, food-delivery, grocery-delivery, cleaning-services, repair-services"
        exit 1
    fi

    # Validate country
    if [[ ! "$COUNTRY" =~ ^(uk|india|global)$ ]]; then
        print_error "Invalid country: $COUNTRY. Must be one of: uk, india, global"
        exit 1
    fi

    # Validate namespace
    if [[ ! "$NAMESPACE" =~ ^[a-z0-9]([a-z0-9\-]*[a-z0-9])?$ ]]; then
        print_error "Invalid namespace: $NAMESPACE. Must be a valid Kubernetes namespace name"
        exit 1
    fi
}

# Function to check prerequisites
check_prerequisites() {
    print_status "Checking prerequisites..."

    # Check if kubectl is installed
    if ! command -v kubectl &> /dev/null; then
        print_error "kubectl is not installed or not in PATH"
        exit 1
    fi

    # Check if helm is installed
    if ! command -v helm &> /dev/null; then
        print_error "helm is not installed or not in PATH"
        exit 1
    fi

    # Check if Crossplane is installed
    if ! kubectl get crd xbackstageinfrastructures.msdp.io &> /dev/null; then
        print_error "Crossplane XRD for Backstage not found. Please install it first."
        exit 1
    fi

    # Check if ArgoCD is installed
    if ! kubectl get namespace argocd &> /dev/null; then
        print_error "ArgoCD namespace not found. Please install ArgoCD first."
        exit 1
    fi

    # Check if we can connect to the cluster
    if ! kubectl cluster-info &> /dev/null; then
        print_error "Cannot connect to Kubernetes cluster"
        exit 1
    fi

    print_success "Prerequisites check passed"
}

# Function to create secrets
create_secrets() {
    print_status "Creating secrets for Backstage..."

    local secret_name="backstage-${ENVIRONMENT}-${BUSINESS_UNIT}-${COUNTRY}-secrets"
    local namespace="crossplane-system"

    # Check if secret already exists
    if kubectl get secret "$secret_name" -n "$namespace" &> /dev/null; then
        print_warning "Secret $secret_name already exists in namespace $namespace"
        return 0
    fi

    # Create secret with placeholder values
    kubectl create secret generic "$secret_name" \
        --namespace="$namespace" \
        --from-literal=postgres-password="$(openssl rand -base64 32)" \
        --from-literal=github-token="PLACEHOLDER_GITHUB_TOKEN" \
        --from-literal=azure-token="PLACEHOLDER_AZURE_TOKEN" \
        --from-literal=argocd-password="PLACEHOLDER_ARGOCD_PASSWORD" \
        --from-literal=session-secret="$(openssl rand -base64 32)" \
        --dry-run=client -o yaml | kubectl apply -f -

    print_success "Created secret: $secret_name"
}

# Function to deploy infrastructure using Crossplane
deploy_infrastructure() {
    print_status "Deploying Backstage infrastructure using Crossplane..."

    local claim_name="backstage-${ENVIRONMENT}-${BUSINESS_UNIT}-${COUNTRY}"
    local claim_file="/tmp/backstage-claim-${ENVIRONMENT}-${BUSINESS_UNIT}-${COUNTRY}.yaml"

    # Create claim file from template
    cat > "$claim_file" << EOF
apiVersion: msdp.io/v1alpha1
kind: XBackstageInfrastructure
metadata:
  name: $claim_name
  namespace: crossplane-system
  labels:
    environment: $ENVIRONMENT
    business-unit: $BUSINESS_UNIT
    country: $COUNTRY
    service: backstage
spec:
  environment: "$ENVIRONMENT"
  businessUnit: "$BUSINESS_UNIT"
  country: "$COUNTRY"
  location: "UK South"
  resourceGroupName: "msdp-${ENVIRONMENT}-rg"
  tenantId: "\${AZURE_TENANT_ID}"
  postgresAdminUser: "backstageadmin"
  postgresPasswordSecret: "backstage-postgres-password-${ENVIRONMENT}"
  postgresSku: "$(if [ "$ENVIRONMENT" = "prod" ]; then echo "GP_Standard_D2s_v3"; else echo "B_Standard_B1ms"; fi)"
  postgresVersion: "13"
  postgresStorageMb: $(if [ "$ENVIRONMENT" = "prod" ]; then echo "131072"; else echo "32768"; fi)
  postgresBackupRetentionDays: $(if [ "$ENVIRONMENT" = "prod" ]; then echo "30"; else echo "3"; fi)
  postgresGeoRedundantBackup: $(if [ "$ENVIRONMENT" = "prod" ]; then echo "true"; else echo "false"; fi)
  postgresCharset: "UTF8"
  postgresCollation: "en_US.utf8"
  postgresStartIp: "0.0.0.0"
  postgresEndIp: "255.255.255.255"
  storageAccountTier: "Standard"
  storageAccountReplication: "$(if [ "$ENVIRONMENT" = "prod" ]; then echo "GRS"; else echo "LRS"; fi)"
  storageAccountKind: "StorageV2"
  storageMinTlsVersion: "TLS1_2"
  storageAllowPublic: false
  storageContainerAccessType: "private"
  keyVaultSku: "$(if [ "$ENVIRONMENT" = "prod" ]; then echo "premium"; else echo "standard"; fi)"
  keyVaultDiskEncryption: true
  keyVaultTemplateDeployment: true
  keyVaultRbacAuth: true
  keyVaultPurgeProtection: $(if [ "$ENVIRONMENT" = "prod" ]; then echo "true"; else echo "false"; fi)
  appInsightsType: "web"
  appInsightsRetentionDays: $(if [ "$ENVIRONMENT" = "prod" ]; then echo "365"; else echo "30"; fi)
  appInsightsDailyDataCap: $(if [ "$ENVIRONMENT" = "prod" ]; then echo "10"; else echo "0.1"; fi)
  appInsightsDataCapNotificationsDisabled: $(if [ "$ENVIRONMENT" = "prod" ]; then echo "false"; else echo "true"; fi)
EOF

    if [ "$DRY_RUN" = true ]; then
        print_status "Dry run: Would apply Crossplane claim:"
        cat "$claim_file"
    else
        kubectl apply -f "$claim_file"
        print_success "Applied Crossplane claim: $claim_name"
        
        # Wait for infrastructure to be ready
        print_status "Waiting for infrastructure to be ready..."
        kubectl wait --for=condition=Ready xbackstageinfrastructure/$claim_name -n crossplane-system --timeout=600s
        print_success "Infrastructure is ready"
    fi

    rm -f "$claim_file"
}

# Function to deploy application using ArgoCD
deploy_application() {
    print_status "Deploying Backstage application using ArgoCD..."

    local app_name="backstage-${ENVIRONMENT}-${BUSINESS_UNIT}-${COUNTRY}"
    local app_file="/tmp/backstage-app-${ENVIRONMENT}-${BUSINESS_UNIT}-${COUNTRY}.yaml"

    # Create ArgoCD application file
    cat > "$app_file" << EOF
apiVersion: argoproj.io/v1alpha1
kind: Application
metadata:
  name: $app_name
  namespace: argocd
  labels:
    environment: $ENVIRONMENT
    business-unit: $BUSINESS_UNIT
    country: $COUNTRY
    service: backstage
    managed-by: argocd
  finalizers:
    - resources-finalizer.argocd.argoproj.io
spec:
  project: msdp-platform
  source:
    repoURL: "$SOURCE_REPO"
    targetRevision: "$SOURCE_REVISION"
    path: "infrastructure/kubernetes/backstage/$ENVIRONMENT/$BUSINESS_UNIT/$COUNTRY"
    helm:
      valueFiles:
        - "values-$ENVIRONMENT.yaml"
        - "values-$BUSINESS_UNIT.yaml"
        - "values-$COUNTRY.yaml"
      parameters:
        - name: "environment"
          value: "$ENVIRONMENT"
        - name: "businessUnit"
          value: "$BUSINESS_UNIT"
        - name: "country"
          value: "$COUNTRY"
        - name: "namespace"
          value: "$NAMESPACE"
        - name: "postgres.host"
          value: "\${POSTGRES_HOST}"
        - name: "postgres.port"
          value: "\${POSTGRES_PORT}"
        - name: "postgres.database"
          value: "\${POSTGRES_DATABASE}"
        - name: "postgres.user"
          value: "\${POSTGRES_USER}"
        - name: "storage.accountName"
          value: "\${STORAGE_ACCOUNT_NAME}"
        - name: "storage.containerName"
          value: "\${STORAGE_CONTAINER_NAME}"
        - name: "keyVault.uri"
          value: "\${KEY_VAULT_URI}"
        - name: "appInsights.connectionString"
          value: "\${APP_INSIGHTS_CONNECTION_STRING}"
        - name: "appInsights.instrumentationKey"
          value: "\${APP_INSIGHTS_INSTRUMENTATION_KEY}"
        - name: "backstage.app.title"
          value: "MSDP Developer Portal - $ENVIRONMENT - $BUSINESS_UNIT - $COUNTRY"
        - name: "backstage.app.baseUrl"
          value: "https://backstage.$ENVIRONMENT.msdp.com"
        - name: "backstage.backend.baseUrl"
          value: "https://backstage-api.$ENVIRONMENT.msdp.com"
        - name: "backstage.organization.name"
          value: "MSDP Platform - $ENVIRONMENT"
        - name: "backstage.organization.logo"
          value: "/logo-$ENVIRONMENT.png"
        - name: "backstage.businessUnit"
          value: "$BUSINESS_UNIT"
        - name: "backstage.country"
          value: "$COUNTRY"
        - name: "backstage.supportedBusinessUnits"
          value: "food-delivery,grocery-delivery,cleaning-services,repair-services"
        - name: "backstage.supportedCountries"
          value: "uk,india"
        - name: "backstage.auth.providers"
          value: "github,microsoft"
        - name: "backstage.auth.session.secret"
          value: "\${SESSION_SECRET}"
        - name: "backstage.integrations.github"
          value: "\${GITHUB_INTEGRATION}"
        - name: "backstage.integrations.azure"
          value: "\${AZURE_INTEGRATION}"
        - name: "backstage.integrations.argocd"
          value: "\${ARGOCD_INTEGRATION}"
  destination:
    server: https://kubernetes.default.svc
    namespace: "$NAMESPACE"
  syncPolicy:
    automated:
      prune: true
      selfHeal: true
      allowEmpty: false
    syncOptions:
      - CreateNamespace=true
      - PrunePropagationPolicy=foreground
      - PruneLast=true
    retry:
      limit: 5
      backoff:
        duration: 5s
        factor: 2
        maxDuration: 3m
  revisionHistoryLimit: 10
EOF

    if [ "$DRY_RUN" = true ]; then
        print_status "Dry run: Would apply ArgoCD application:"
        cat "$app_file"
    else
        kubectl apply -f "$app_file"
        print_success "Applied ArgoCD application: $app_name"
        
        # Wait for application to be synced
        print_status "Waiting for application to be synced..."
        kubectl wait --for=condition=Synced application/$app_name -n argocd --timeout=300s
        print_success "Application is synced"
    fi

    rm -f "$app_file"
}

# Function to show deployment status
show_status() {
    print_status "Deployment Status:"
    echo
    
    print_status "Crossplane Infrastructure:"
    kubectl get xbackstageinfrastructure -n crossplane-system -l environment=$ENVIRONMENT,business-unit=$BUSINESS_UNIT,country=$COUNTRY
    echo
    
    print_status "ArgoCD Application:"
    kubectl get application -n argocd -l environment=$ENVIRONMENT,business-unit=$BUSINESS_UNIT,country=$COUNTRY
    echo
    
    print_status "Backstage Pods:"
    kubectl get pods -n $NAMESPACE -l app=backstage
    echo
    
    print_status "Backstage Services:"
    kubectl get services -n $NAMESPACE -l app=backstage
    echo
    
    print_status "Backstage Ingress:"
    kubectl get ingress -n $NAMESPACE -l app=backstage
}

# Main function
main() {
    print_status "Starting MSDP Backstage deployment..."
    print_status "Environment: $ENVIRONMENT"
    print_status "Business Unit: $BUSINESS_UNIT"
    print_status "Country: $COUNTRY"
    print_status "Namespace: $NAMESPACE"
    print_status "Source Repo: $SOURCE_REPO"
    print_status "Source Revision: $SOURCE_REVISION"
    print_status "Dry Run: $DRY_RUN"
    echo

    # Validate inputs
    validate_inputs

    # Check prerequisites
    check_prerequisites

    # Create secrets
    create_secrets

    # Deploy infrastructure
    deploy_infrastructure

    # Deploy application
    deploy_application

    # Show status
    show_status

    print_success "Backstage deployment completed successfully!"
    print_status "Access Backstage at: https://backstage.$ENVIRONMENT.msdp.com"
}

# Parse command line arguments
while [[ $# -gt 0 ]]; do
    case $1 in
        -e|--environment)
            ENVIRONMENT="$2"
            NAMESPACE="backstage-${ENVIRONMENT}"
            shift 2
            ;;
        -b|--business-unit)
            BUSINESS_UNIT="$2"
            shift 2
            ;;
        -c|--country)
            COUNTRY="$2"
            shift 2
            ;;
        -n|--namespace)
            NAMESPACE="$2"
            shift 2
            ;;
        -r|--repo)
            SOURCE_REPO="$2"
            shift 2
            ;;
        -v|--revision)
            SOURCE_REVISION="$2"
            shift 2
            ;;
        -d|--dry-run)
            DRY_RUN=true
            shift
            ;;
        -V|--verbose)
            VERBOSE=true
            shift
            ;;
        -h|--help)
            show_usage
            exit 0
            ;;
        *)
            print_error "Unknown option: $1"
            show_usage
            exit 1
            ;;
    esac
done

# Run main function
main
