#!/bin/bash

# Certificate Management Generation Script
# Generates Certificate and ExternalSecret resources for HTTPS ingress

set -euo pipefail

INGRESS_NAME="${1:-}"
NAMESPACE="${2:-}"
SECRET_NAME="${3:-}"
HOSTS="${4:-}"
ENVIRONMENT="${5:-dev}"
OUTPUT_DIR="${6:-/tmp/certificate-management}"

if [ -z "$INGRESS_NAME" ] || [ -z "$NAMESPACE" ] || [ -z "$SECRET_NAME" ] || [ -z "$HOSTS" ]; then
    echo "Usage: $0 <ingress_name> <namespace> <secret_name> <hosts> <environment> [output_dir]"
    echo "Example: $0 argocd-ingress argocd argocd-tls 'argocd.dev.aztech-msdp.com' dev"
    exit 1
fi

echo "🔧 Generating certificate management for $INGRESS_NAME in $NAMESPACE..."

# Create output directory
mkdir -p "$OUTPUT_DIR"

# Extract primary host (first host in the list)
PRIMARY_HOST=$(echo "$HOSTS" | head -1)
COMPONENT_NAME=$(echo "$PRIMARY_HOST" | cut -d'.' -f1)

echo "📋 Certificate Details:"
echo "  - Component: $COMPONENT_NAME"
echo "  - Primary Host: $PRIMARY_HOST"
echo "  - Secret Name: $SECRET_NAME"
echo "  - Namespace: $NAMESPACE"
echo "  - Hosts: $HOSTS"

# Validate required parameters
if [ -z "$SECRET_NAME" ] || [ -z "$NAMESPACE" ] || [ -z "$HOSTS" ]; then
    echo "❌ Missing required parameters:"
    echo "  - Secret Name: $SECRET_NAME"
    echo "  - Namespace: $NAMESPACE"
    echo "  - Hosts: $HOSTS"
    exit 1
fi

# Generate Certificate resource for cert-manager
cat > "$OUTPUT_DIR/${COMPONENT_NAME}-certificate.yaml" << EOF
# ${COMPONENT_NAME^} Certificate for cert-manager
apiVersion: cert-manager.io/v1
kind: Certificate
metadata:
  name: ${COMPONENT_NAME}-tls
  namespace: ${NAMESPACE}
spec:
  secretName: ${SECRET_NAME}
  issuerRef:
    name: letsencrypt-prod
    kind: ClusterIssuer
  dnsNames:
$(echo "$HOSTS" | tr ' ' '\n' | while read -r host; do
  if [ -n "$host" ] && [ "$host" != "null" ]; then
    echo "    - $host"
  fi
done)
EOF

# Generate ExternalSecret resource for External Secrets Operator
cat > "$OUTPUT_DIR/${COMPONENT_NAME}-externalsecret.yaml" << EOF
# ${COMPONENT_NAME^} ExternalSecret for certificate sync
apiVersion: external-secrets.io/v1beta1
kind: ExternalSecret
metadata:
  name: ${SECRET_NAME}
  namespace: ${NAMESPACE}
spec:
  refreshInterval: "1h"
  secretStoreRef:
    name: azure-keyvault-store
    kind: ClusterSecretStore
  target:
    name: ${SECRET_NAME}
    creationPolicy: Owner
    template:
      type: kubernetes.io/tls
      data:
        tls.crt: "{{ .certificate }}"
        tls.key: "{{ .privateKey }}"
  data:
  - secretKey: certificate
    remoteRef:
      key: ${ENVIRONMENT}-${COMPONENT_NAME}-tls
  - secretKey: privateKey
    remoteRef:
      key: ${ENVIRONMENT}-${COMPONENT_NAME}-key
EOF

echo "✅ Generated certificate management files:"
echo "  - Certificate: $OUTPUT_DIR/${COMPONENT_NAME}-certificate.yaml"
echo "  - ExternalSecret: $OUTPUT_DIR/${COMPONENT_NAME}-externalsecret.yaml"
