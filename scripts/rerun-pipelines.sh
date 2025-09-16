#!/bin/bash
set -euo pipefail

# Script to rerun the Azure infrastructure pipelines
# Usage: ./scripts/rerun-pipelines.sh [network|aks|both] [plan|apply|destroy]

COMPONENT="${1:-both}"
ACTION="${2:-plan}"
ENVIRONMENT="${3:-dev}"

echo "🚀 Rerunning Azure Infrastructure Pipelines"
echo "==========================================="
echo "Component: $COMPONENT"
echo "Action: $ACTION"
echo "Environment: $ENVIRONMENT"
echo ""

# Function to run network pipeline
run_network() {
    echo "📡 Running Network Infrastructure Pipeline..."
    gh workflow run azure-network.yml \
        -f action="$ACTION" \
        -f environment="$ENVIRONMENT"
    
    echo "✅ Network pipeline triggered"
    echo "   View at: https://github.com/msdp-platform/msdp-devops-infrastructure/actions/workflows/azure-network.yml"
}

# Function to run AKS pipeline
run_aks() {
    echo "☸️  Running AKS Clusters Pipeline..."
    gh workflow run aks.yml \
        -f action="$ACTION" \
        -f environment="$ENVIRONMENT"
    
    echo "✅ AKS pipeline triggered"
    echo "   View at: https://github.com/msdp-platform/msdp-devops-infrastructure/actions/workflows/aks.yml"
}

# Function to check workflow status
check_status() {
    echo ""
    echo "📊 Checking recent workflow runs..."
    gh run list --limit 5
}

# Main execution
case "$COMPONENT" in
    network)
        run_network
        ;;
    aks)
        run_aks
        ;;
    both)
        run_network
        echo ""
        echo "⏳ Waiting 5 seconds before starting AKS pipeline..."
        sleep 5
        run_aks
        ;;
    *)
        echo "❌ Invalid component: $COMPONENT"
        echo "   Valid options: network, aks, both"
        exit 1
        ;;
esac

echo ""
echo "🔍 To monitor the pipelines:"
echo "   gh run watch"
echo "   gh run list"
echo ""
echo "📋 To view logs:"
echo "   gh run view --log"
echo ""

# Optional: Watch the latest run
read -p "Do you want to watch the latest run? (y/n) " -n 1 -r
echo
if [[ $REPLY =~ ^[Yy]$ ]]; then
    echo "Waiting for run to start..."
    sleep 5
    gh run watch
fi