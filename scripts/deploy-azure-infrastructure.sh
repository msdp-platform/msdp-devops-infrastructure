#!/bin/bash
set -euo pipefail

# Deploy Azure Infrastructure in Correct Order
# This script ensures network is deployed before AKS

ENVIRONMENT="${1:-dev}"
ACTION="${2:-apply}"

echo "🚀 Azure Infrastructure Deployment"
echo "=================================="
echo "Environment: $ENVIRONMENT"
echo "Action: $ACTION"
echo ""

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Function to check if resource group exists
check_network_exists() {
    echo "🔍 Checking if network infrastructure exists..."
    
    if az group show --name "rg-msdp-network-$ENVIRONMENT" &>/dev/null; then
        echo -e "${GREEN}✅ Resource group exists${NC}"
        
        # Check VNet
        if az network vnet show --resource-group "rg-msdp-network-$ENVIRONMENT" --name "vnet-msdp-$ENVIRONMENT" &>/dev/null; then
            echo -e "${GREEN}✅ Virtual network exists${NC}"
            
            # Check subnets
            SUBNETS=$(az network vnet subnet list --resource-group "rg-msdp-network-$ENVIRONMENT" --vnet-name "vnet-msdp-$ENVIRONMENT" --query "[].name" -o tsv)
            if [ -n "$SUBNETS" ]; then
                echo -e "${GREEN}✅ Subnets exist: $SUBNETS${NC}"
                return 0
            else
                echo -e "${YELLOW}⚠️  No subnets found${NC}"
                return 1
            fi
        else
            echo -e "${YELLOW}⚠️  Virtual network not found${NC}"
            return 1
        fi
    else
        echo -e "${YELLOW}⚠️  Resource group not found${NC}"
        return 1
    fi
}

# Function to deploy network
deploy_network() {
    echo ""
    echo "📡 Deploying Network Infrastructure..."
    echo "--------------------------------------"
    
    if [ "$ACTION" == "plan" ]; then
        echo "Running network plan..."
        gh workflow run azure-network.yml -f action=plan -f environment="$ENVIRONMENT"
    else
        echo "Applying network infrastructure..."
        gh workflow run azure-network.yml -f action=apply -f environment="$ENVIRONMENT"
        
        echo ""
        echo "⏳ Waiting for network deployment to start..."
        sleep 10
        
        # Get the latest run ID
        RUN_ID=$(gh run list --workflow=azure-network.yml --limit=1 --json databaseId --jq '.[0].databaseId')
        
        if [ -n "$RUN_ID" ]; then
            echo "📊 Monitoring workflow run #$RUN_ID"
            echo "   View at: https://github.com/msdp-platform/msdp-devops-infrastructure/actions/runs/$RUN_ID"
            
            # Wait for completion
            gh run watch "$RUN_ID" --exit-status || {
                echo -e "${RED}❌ Network deployment failed!${NC}"
                echo "Check the logs: gh run view $RUN_ID --log"
                exit 1
            }
            
            echo -e "${GREEN}✅ Network deployment completed successfully!${NC}"
        fi
    fi
}

# Function to deploy AKS
deploy_aks() {
    echo ""
    echo "☸️  Deploying AKS Clusters..."
    echo "----------------------------"
    
    # Check if network exists first
    if ! check_network_exists; then
        echo -e "${RED}❌ Network infrastructure must be deployed first!${NC}"
        echo "Run: $0 $ENVIRONMENT apply"
        exit 1
    fi
    
    echo "Running AKS $ACTION..."
    gh workflow run aks.yml -f action="$ACTION" -f environment="$ENVIRONMENT"
    
    if [ "$ACTION" == "apply" ]; then
        echo ""
        echo "⏳ Waiting for AKS deployment to start..."
        sleep 10
        
        # Get the latest run ID
        RUN_ID=$(gh run list --workflow=aks.yml --limit=1 --json databaseId --jq '.[0].databaseId')
        
        if [ -n "$RUN_ID" ]; then
            echo "📊 Monitoring workflow run #$RUN_ID"
            echo "   View at: https://github.com/msdp-platform/msdp-devops-infrastructure/actions/runs/$RUN_ID"
            
            # Optional: Watch the run
            read -p "Do you want to watch the deployment? (y/n) " -n 1 -r
            echo
            if [[ $REPLY =~ ^[Yy]$ ]]; then
                gh run watch "$RUN_ID" --exit-status || {
                    echo -e "${RED}❌ AKS deployment failed!${NC}"
                    echo "Check the logs: gh run view $RUN_ID --log"
                    exit 1
                }
                echo -e "${GREEN}✅ AKS deployment completed successfully!${NC}"
            fi
        fi
    fi
}

# Main execution
echo "🏁 Starting deployment process..."

# Step 1: Check/Deploy Network
if check_network_exists; then
    echo ""
    read -p "Network already exists. Redeploy network? (y/n) " -n 1 -r
    echo
    if [[ $REPLY =~ ^[Yy]$ ]]; then
        deploy_network
    else
        echo "Skipping network deployment."
    fi
else
    echo -e "${YELLOW}Network infrastructure not found. Deploying...${NC}"
    deploy_network
    
    # Wait a bit for resources to be fully ready
    if [ "$ACTION" == "apply" ]; then
        echo "⏳ Waiting 30 seconds for resources to be fully ready..."
        sleep 30
    fi
fi

# Step 2: Deploy AKS
echo ""
read -p "Deploy AKS clusters? (y/n) " -n 1 -r
echo
if [[ $REPLY =~ ^[Yy]$ ]]; then
    deploy_aks
else
    echo "Skipping AKS deployment."
fi

# Summary
echo ""
echo "📊 Deployment Summary"
echo "===================="

if check_network_exists; then
    echo -e "${GREEN}✅ Network: Deployed${NC}"
    
    # Get AKS cluster status
    CLUSTERS=$(az aks list --resource-group "rg-msdp-network-$ENVIRONMENT" --query "[].name" -o tsv 2>/dev/null)
    if [ -n "$CLUSTERS" ]; then
        echo -e "${GREEN}✅ AKS Clusters: $CLUSTERS${NC}"
    else
        echo -e "${YELLOW}⚠️  AKS Clusters: Not deployed${NC}"
    fi
else
    echo -e "${RED}❌ Network: Not deployed${NC}"
    echo -e "${RED}❌ AKS Clusters: Cannot deploy without network${NC}"
fi

echo ""
echo "🎯 Next Steps:"
if ! check_network_exists; then
    echo "1. Fix any network deployment issues"
    echo "2. Run: $0 $ENVIRONMENT apply"
else
    if [ -z "$CLUSTERS" ]; then
        echo "1. Deploy AKS clusters: $0 $ENVIRONMENT apply"
    else
        echo "1. Get AKS credentials:"
        echo "   az aks get-credentials --resource-group rg-msdp-network-$ENVIRONMENT --name <cluster-name>"
        echo "2. Install KEDA for advanced scaling:"
        echo "   helm install keda kedacore/keda --namespace keda --create-namespace"
    fi
fi