#!/bin/bash

# Karpenter Cost-Effective Installation Script
# This script installs Karpenter with cost-optimized configuration

set -e

echo "🚀 Installing Karpenter with Cost-Effective Configuration..."

# Step 1: Create Karpenter namespace
echo "📋 Step 1: Creating Karpenter namespace..."
kubectl create namespace karpenter --dry-run=client -o yaml | kubectl apply -f -

# Step 2: Create Karpenter service account
echo "📋 Step 2: Creating Karpenter service account..."
cat <<EOF | kubectl apply -f -
apiVersion: v1
kind: ServiceAccount
metadata:
  name: karpenter
  namespace: karpenter
  annotations:
    azure.workload.identity/client-id: "fc40ae11-55f4-496d-8c16-1004ed073afb"
    azure.workload.identity/tenant-id: "a4474822-c84f-4bd1-bc35-baed17234c9f"
EOF

# Step 3: Create Karpenter cluster role
echo "📋 Step 3: Creating Karpenter cluster role..."
cat <<EOF | kubectl apply -f -
apiVersion: rbac.authorization.k8s.io/v1
kind: ClusterRole
metadata:
  name: karpenter
rules:
- apiGroups: [""]
  resources: ["nodes", "pods", "events", "persistentvolumes", "persistentvolumeclaims"]
  verbs: ["get", "list", "watch", "create", "update", "patch", "delete"]
- apiGroups: ["apps"]
  resources: ["daemonsets", "deployments", "replicasets"]
  verbs: ["get", "list", "watch"]
- apiGroups: ["policy"]
  resources: ["poddisruptionbudgets"]
  verbs: ["get", "list", "watch"]
- apiGroups: ["storage.k8s.io"]
  resources: ["storageclasses"]
  verbs: ["get", "list", "watch"]
- apiGroups: ["karpenter.sh"]
  resources: ["nodepools", "nodeclaims"]
  verbs: ["get", "list", "watch", "create", "update", "patch", "delete"]
EOF

# Step 4: Create Karpenter cluster role binding
echo "📋 Step 4: Creating Karpenter cluster role binding..."
cat <<EOF | kubectl apply -f -
apiVersion: rbac.authorization.k8s.io/v1
kind: ClusterRoleBinding
metadata:
  name: karpenter
roleRef:
  apiGroup: rbac.authorization.k8s.io
  kind: ClusterRole
  name: karpenter
subjects:
- kind: ServiceAccount
  name: karpenter
  namespace: karpenter
EOF

# Step 5: Create AKS Node Class
echo "📋 Step 5: Creating AKS Node Class..."
cat <<EOF | kubectl apply -f -
apiVersion: karpenter.azure.com/v1alpha2
kind: AKSNodeClass
metadata:
  name: default
spec:
  amiFamily: Ubuntu2204
  osDisk:
    cachingType: ReadOnly
    storageAccountType: Premium_LRS
    diskSizeGB: 128
  userData: |
    #!/bin/bash
    /etc/eks/bootstrap.sh delivery-platform-aks
  tags:
    karpenter.sh/discovery: delivery-platform-aks
EOF

# Step 6: Create Cost-Effective NodePool
echo "📋 Step 6: Creating Cost-Effective NodePool..."
cat <<EOF | kubectl apply -f -
apiVersion: karpenter.sh/v1
kind: NodePool
metadata:
  name: cost-effective-pool
spec:
  # Cost optimization settings
  limits:
    cpu: 4
    memory: 16Gi
  
  # Template for nodes
  template:
    metadata:
      labels:
        karpenter.sh/nodepool: cost-effective-pool
        kubernetes.azure.com/mode: user
    spec:
      # Node class reference
      nodeClassRef:
        apiVersion: karpenter.azure.com/v1alpha2
        kind: AKSNodeClass
        name: default
      
      # Node requirements
      requirements:
        - key: kubernetes.io/arch
          operator: In
          values: ["amd64"]
        - key: kubernetes.io/os
          operator: In
          values: ["linux"]
        - key: karpenter.sh/capacity-type
          operator: In
          values: ["spot", "on-demand"]  # Prefer spot instances for cost savings
        - key: karpenter.azure.com/sku-family
          operator: In
          values: ["B", "D"]  # Cost-effective VM families
        - key: karpenter.azure.com/sku-cpu
          operator: In
          values: ["2", "4"]  # Limit to 2-4 vCPUs
        - key: karpenter.azure.com/sku-memory
          operator: In
          values: ["4096", "8192", "16384"]  # 4-16GB RAM
      
      # Taints to prevent system pods from scheduling here
      taints:
        - key: karpenter.sh/nodepool
          value: cost-effective-pool
          effect: NoSchedule
  
  # Disruption settings for cost optimization
  disruption:
    # Consolidate nodes when they're empty or underutilized
    consolidationPolicy: WhenEmptyOrUnderutilized
    consolidateAfter: 30s  # Quick consolidation for cost savings
    
    # Budget for disruption
    budgets:
      - nodes: 50%  # Allow up to 50% of nodes to be disrupted at once
        consolidateAfter: 30s
        expireAfter: 1h  # Expire nodes after 1 hour of inactivity
EOF

# Step 7: Create System NodePool (minimal)
echo "📋 Step 7: Creating System NodePool..."
cat <<EOF | kubectl apply -f -
apiVersion: karpenter.sh/v1
kind: NodePool
metadata:
  name: system-pool
spec:
  # Minimal system pool
  limits:
    cpu: 2
    memory: 8Gi
  
  template:
    metadata:
      labels:
        karpenter.sh/nodepool: system-pool
        kubernetes.azure.com/mode: system
    spec:
      nodeClassRef:
        apiVersion: karpenter.azure.com/v1alpha2
        kind: AKSNodeClass
        name: default
      
      requirements:
        - key: kubernetes.io/arch
          operator: In
          values: ["amd64"]
        - key: kubernetes.io/os
          operator: In
          values: ["linux"]
        - key: karpenter.sh/capacity-type
          operator: In
          values: ["on-demand"]  # System pods need reliable instances
        - key: karpenter.azure.com/sku-family
          operator: In
          values: ["B"]  # Small system instances
        - key: karpenter.azure.com/sku-cpu
          operator: In
          values: ["2"]
        - key: karpenter.azure.com/sku-memory
          operator: In
          values: ["4096"]
      
      # Taints for system pods only
      taints:
        - key: CriticalAddonsOnly
          value: "true"
          effect: NoSchedule
  
  # Conservative disruption for system pool
  disruption:
    consolidationPolicy: WhenEmptyOrUnderutilized
    consolidateAfter: 5m  # Longer wait for system stability
    budgets:
      - nodes: 25%  # Conservative disruption
        consolidateAfter: 5m
        expireAfter: 2h
EOF

# Step 8: Deploy Karpenter Controller
echo "📋 Step 8: Deploying Karpenter Controller..."
cat <<EOF | kubectl apply -f -
apiVersion: apps/v1
kind: Deployment
metadata:
  name: karpenter
  namespace: karpenter
spec:
  replicas: 1
  selector:
    matchLabels:
      app: karpenter
  template:
    metadata:
      labels:
        app: karpenter
    spec:
      serviceAccountName: karpenter
      containers:
        - name: karpenter
          image: public.ecr.aws/karpenter/karpenter:v0.37.0
          args:
            - --cluster-name=delivery-platform-aks
            - --cluster-endpoint=https://delivery-p-delivery-platfor-ecd977-f3mobive.hcp.eastus.azmk8s.io
            - --aws-default-instance-profile=KarpenterNodeInstanceProfile-delivery-platform-aks
            - --aws-cluster-name=delivery-platform-aks
            - --aws-partition=aws
            - --aws-region=us-east-1
            - --log-level=info
            - --metrics-bind-address=:8080
            - --webhook-port=9443
            - --leader-elect=true
            - --leader-elect-lease-duration=15s
            - --leader-elect-renew-deadline=10s
            - --leader-elect-retry-period=2s
          env:
            - name: KARPENTER_CLUSTER_NAME
              value: delivery-platform-aks
            - name: KARPENTER_CLUSTER_ENDPOINT
              value: https://delivery-p-delivery-platfor-ecd977-f3mobive.hcp.eastus.azmk8s.io
          ports:
            - name: webhook
              containerPort: 9443
            - name: metrics
              containerPort: 8080
          resources:
            requests:
              cpu: 100m
              memory: 128Mi
            limits:
              cpu: 200m
              memory: 256Mi
          livenessProbe:
            httpGet:
              path: /healthz
              port: 8080
            initialDelaySeconds: 30
            periodSeconds: 10
          readinessProbe:
            httpGet:
              path: /readyz
              port: 8080
            initialDelaySeconds: 5
            periodSeconds: 5
EOF

# Step 9: Wait for Karpenter to be ready
echo "📋 Step 9: Waiting for Karpenter to be ready..."
kubectl wait --for=condition=available --timeout=300s deployment/karpenter -n karpenter

# Step 10: Verify installation
echo "📋 Step 10: Verifying installation..."
echo "Karpenter pods:"
kubectl get pods -n karpenter

echo "NodePools:"
kubectl get nodepools

echo "AKS Node Classes:"
kubectl get aksnodeclasses

echo "🎉 Karpenter installation completed successfully!"
echo "✅ Cost-effective configuration applied:"
echo "   - Spot instances preferred for cost savings"
echo "   - Quick scale-down (30s consolidation)"
echo "   - Minimal system pool (2 vCPU, 4GB RAM)"
echo "   - Cost-effective user pool (2-4 vCPU, 4-16GB RAM)"
echo "   - Proper taints to separate system and user workloads"
