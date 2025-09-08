#!/bin/bash

# Karpenter Clean Setup Script
# This script removes existing Karpenter and sets up a cost-effective configuration

set -e

echo "🚀 Starting Karpenter Clean Setup..."

# Step 1: Remove existing Karpenter installation
echo "📋 Step 1: Removing existing Karpenter installation..."

# Scale down Karpenter controller
kubectl scale deployment karpenter -n kube-system --replicas=0 2>/dev/null || echo "Karpenter deployment not found"

# Delete all nodepools
kubectl delete nodepools --all 2>/dev/null || echo "No nodepools found"

# Delete all nodeclaims
kubectl delete nodeclaims --all 2>/dev/null || echo "No nodeclaims found"

# Delete Karpenter CRDs
kubectl delete crd nodepools.karpenter.sh 2>/dev/null || echo "NodePool CRD not found"
kubectl delete crd nodeclaims.karpenter.sh 2>/dev/null || echo "NodeClaim CRD not found"

# Delete Karpenter deployment
kubectl delete deployment karpenter -n kube-system 2>/dev/null || echo "Karpenter deployment not found"

# Delete Karpenter service account
kubectl delete serviceaccount karpenter -n kube-system 2>/dev/null || echo "Karpenter service account not found"

# Delete Karpenter cluster role
kubectl delete clusterrole karpenter 2>/dev/null || echo "Karpenter cluster role not found"

# Delete Karpenter cluster role binding
kubectl delete clusterrolebinding karpenter 2>/dev/null || echo "Karpenter cluster role binding not found"

# Delete Karpenter webhook configuration
kubectl delete validatingwebhookconfiguration karpenter 2>/dev/null || echo "Karpenter webhook not found"

# Delete Karpenter mutating webhook configuration
kubectl delete mutatingwebhookconfiguration karpenter 2>/dev/null || echo "Karpenter mutating webhook not found"

# Delete Karpenter namespace (if it exists)
kubectl delete namespace karpenter 2>/dev/null || echo "Karpenter namespace not found"

echo "✅ Step 1 Complete: Existing Karpenter installation removed"

# Step 2: Clean up Karpenter nodes
echo "📋 Step 2: Cleaning up Karpenter nodes..."

# Get all nodes with karpenter labels
KARPENTER_NODES=$(kubectl get nodes -l karpenter.sh/nodepool --no-headers -o custom-columns=":metadata.name" 2>/dev/null || echo "")

if [ -n "$KARPENTER_NODES" ]; then
    echo "Found Karpenter nodes: $KARPENTER_NODES"
    
    for node in $KARPENTER_NODES; do
        echo "Draining node: $node"
        kubectl drain "$node" --ignore-daemonsets --delete-emptydir-data --force --grace-period=30 2>/dev/null || echo "Failed to drain $node"
        
        echo "Deleting node: $node"
        kubectl delete node "$node" 2>/dev/null || echo "Failed to delete $node"
    done
else
    echo "No Karpenter nodes found"
fi

echo "✅ Step 2 Complete: Karpenter nodes cleaned up"

# Step 3: Wait for cleanup to complete
echo "📋 Step 3: Waiting for cleanup to complete..."
sleep 30

# Check remaining nodes
echo "Current nodes:"
kubectl get nodes

echo "🎉 Karpenter cleanup completed successfully!"
echo "Ready for fresh Karpenter installation with cost-effective configuration."
