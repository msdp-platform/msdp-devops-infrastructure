# 🧪 Testing Guide - AWS EKS Platform

## 📋 **Overview**

This guide provides testing procedures for validating the AWS EKS platform functionality and performance.

## 🎯 **Testing Objectives**

- **Functionality**: Verify all components work correctly
- **Performance**: Validate scaling and performance
- **Security**: Test security configurations
- **Cost Optimization**: Verify cost optimization features

## 🧪 **Test Categories**

### **1. Infrastructure Tests**

#### **Cluster Health**
```bash
# Test cluster connectivity
kubectl cluster-info

# Test node status
kubectl get nodes

# Test system pods
kubectl get pods -n kube-system
```

#### **Network Tests**
```bash
# Test DNS resolution
kubectl run test-dns --image=busybox --rm -it -- nslookup kubernetes.default

# Test network connectivity
kubectl run test-connectivity --image=busybox --rm -it -- wget -qO- http://kubernetes.default
```

### **2. Karpenter Tests**

#### **Scaling Tests**
```bash
# Deploy test workload
kubectl apply -f - <<EOF
apiVersion: apps/v1
kind: Deployment
metadata:
  name: test-scaling
spec:
  replicas: 10
  selector:
    matchLabels:
      app: test-scaling
  template:
    metadata:
      labels:
        app: test-scaling
    spec:
      containers:
      - name: test
        image: nginx
        resources:
          requests:
            cpu: 100m
            memory: 128Mi
EOF

# Monitor scaling
kubectl get nodes -w
kubectl get pods -w
```

#### **Instance Type Tests**
```bash
# Check instance types
kubectl get nodes -o wide

# Verify spot instances
aws ec2 describe-instances --filters "Name=tag:karpenter.sh/discovery,Values=msdp-eks-dev"
```

### **3. Platform Component Tests**

#### **ArgoCD Tests**
```bash
# Check ArgoCD status
kubectl get pods -n argocd

# Test ArgoCD connectivity
kubectl port-forward -n argocd svc/argocd-server 8080:443
```

#### **Prometheus Tests**
```bash
# Check Prometheus status
kubectl get pods -n monitoring

# Test metrics collection
kubectl port-forward -n monitoring svc/prometheus-server 9090:80
```

#### **Grafana Tests**
```bash
# Check Grafana status
kubectl get pods -n monitoring

# Test Grafana access
kubectl port-forward -n monitoring svc/grafana 3000:80
```

### **4. Security Tests**

#### **Authentication Tests**
```bash
# Test RBAC
kubectl auth can-i get pods
kubectl auth can-i create deployments

# Test service account permissions
kubectl auth can-i get pods --as=system:serviceaccount:default:default
```

#### **Network Security Tests**
```bash
# Test network policies
kubectl get networkpolicies

# Test security groups
aws ec2 describe-security-groups --filters "Name=group-name,Values=*eks*"
```

### **5. Cost Optimization Tests**

#### **Spot Instance Tests**
```bash
# Verify spot instance usage
aws ec2 describe-spot-instance-requests

# Check instance pricing
aws pricing get-products --service-code AmazonEC2 --filters Type=TERM_MATCH,Field=instanceType,Value=t4g.medium
```

#### **Auto-scaling Tests**
```bash
# Test horizontal pod autoscaler
kubectl get hpa

# Test vertical pod autoscaler
kubectl get vpa
```

## 📊 **Performance Tests**

### **Load Testing**
```bash
# Deploy load test
kubectl apply -f - <<EOF
apiVersion: apps/v1
kind: Deployment
metadata:
  name: load-test
spec:
  replicas: 20
  selector:
    matchLabels:
      app: load-test
  template:
    metadata:
      labels:
        app: load-test
    spec:
      containers:
      - name: load-test
        image: nginx
        resources:
          requests:
            cpu: 200m
            memory: 256Mi
          limits:
            cpu: 500m
            memory: 512Mi
EOF
```

### **Scaling Performance**
```bash
# Monitor scaling time
time kubectl scale deployment load-test --replicas=50

# Check node provisioning time
kubectl get events --sort-by=.metadata.creationTimestamp
```

## 🔒 **Security Tests**

### **Penetration Testing**
```bash
# Test pod security
kubectl run test-pod --image=busybox --rm -it -- sh

# Test network access
kubectl run test-network --image=busybox --rm -it -- wget -qO- http://kubernetes.default
```

### **Compliance Tests**
```bash
# Run security scans
kubectl get pods -A -o jsonpath='{range .items[*]}{.metadata.name}{"\t"}{.spec.securityContext}{"\n"}{end}'

# Check RBAC policies
kubectl get roles,rolebindings,clusterroles,clusterrolebindings
```

## 📈 **Monitoring Tests**

### **Metrics Collection**
```bash
# Test Prometheus metrics
curl http://prometheus-server.monitoring.svc.cluster.local:9090/api/v1/query?query=up

# Test Grafana dashboards
curl http://grafana.monitoring.svc.cluster.local:3000/api/health
```

### **Alert Testing**
```bash
# Test alert rules
kubectl get prometheusrules -n monitoring

# Test alertmanager
kubectl port-forward -n monitoring svc/alertmanager 9093:80
```

## 🧪 **Test Automation**

### **GitHub Actions Tests**
```yaml
# Test workflow
name: Platform Tests
on: [push, pull_request]

jobs:
  test:
    runs-on: ubuntu-latest
    steps:
      - name: Test cluster connectivity
        run: kubectl cluster-info
      
      - name: Test Karpenter
        run: kubectl get nodepools
      
      - name: Test platform components
        run: kubectl get pods -A
```

### **Test Scripts**
```bash
#!/bin/bash
# test-platform.sh

echo "Testing EKS Platform..."

# Test cluster
kubectl cluster-info

# Test Karpenter
kubectl get nodepools

# Test components
kubectl get pods -A

echo "Platform tests completed!"
```

## 📋 **Test Checklist**

### **Pre-deployment**
- [ ] Infrastructure tests
- [ ] Security tests
- [ ] Network tests

### **Post-deployment**
- [ ] Component functionality
- [ ] Scaling tests
- [ ] Performance tests
- [ ] Cost optimization tests

### **Ongoing**
- [ ] Regular health checks
- [ ] Performance monitoring
- [ ] Security scans
- [ ] Cost analysis

---

**Last Updated**: December 2024  
**Version**: 3.0.0  
**Maintainer**: DevOps Team
