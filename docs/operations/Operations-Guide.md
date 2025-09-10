# 🔧 Operations Guide - AWS EKS Platform

## 📋 **Overview**

This guide provides operational procedures for managing and maintaining the AWS EKS platform.

## 🔍 **Monitoring & Observability**

### **Prometheus Metrics**
```bash
# Check Prometheus status
kubectl get pods -n monitoring

# Access Prometheus UI
kubectl port-forward -n monitoring svc/prometheus-server 9090:80
```

### **Grafana Dashboards**
```bash
# Access Grafana UI
kubectl port-forward -n monitoring svc/grafana 3000:80

# Default credentials: admin/admin
```

### **CloudWatch Integration**
- Metrics automatically sent to CloudWatch
- Logs aggregated in CloudWatch Logs
- Alerts configured in CloudWatch

## 🚀 **Scaling Operations**

### **Karpenter Scaling**
```bash
# Check NodePools
kubectl get nodepools

# Check node status
kubectl get nodes

# Monitor scaling events
kubectl logs -n karpenter deployment/karpenter
```

### **Manual Scaling**
```bash
# Scale deployment
kubectl scale deployment my-app --replicas=5

# Update NodePool limits
kubectl patch nodepool cost-optimized --type merge -p '{"spec":{"limits":{"cpu":"2000"}}}'
```

## 🔒 **Security Operations**

### **Access Management**
```bash
# Check RBAC
kubectl get roles,rolebindings

# Check service accounts
kubectl get serviceaccounts

# Verify IAM roles
aws iam list-roles --profile AWSAdministratorAccess-319422413814
```

### **Secrets Management**
```bash
# Check secrets
kubectl get secrets

# Update secrets in AWS Secrets Manager
aws secretsmanager update-secret --secret-id my-secret --secret-string "new-value"
```

## 🔄 **Deployment Operations**

### **ArgoCD Management**
```bash
# Check ArgoCD applications
kubectl get applications -n argocd

# Access ArgoCD UI
kubectl port-forward -n argocd svc/argocd-server 8080:443
```

### **GitOps Workflow**
1. Make changes to Git repository
2. ArgoCD automatically syncs changes
3. Monitor deployment status
4. Rollback if needed

## 🛠️ **Maintenance Operations**

### **Cluster Updates**
```bash
# Update cluster version
aws eks update-cluster-version --name msdp-eks-dev --kubernetes-version 1.29

# Update node groups
aws eks update-nodegroup-version --cluster-name msdp-eks-dev --nodegroup-name system
```

### **Component Updates**
```bash
# Update Helm charts
helm upgrade karpenter karpenter/karpenter -n karpenter

# Update ArgoCD
helm upgrade argocd argo/argo-cd -n argocd
```

## 📊 **Cost Optimization**

### **Instance Monitoring**
```bash
# Check instance types
kubectl get nodes -o wide

# Monitor spot instance usage
aws ec2 describe-spot-instance-requests
```

### **Cost Analysis**
- Use AWS Cost Explorer
- Monitor Karpenter instance selection
- Review spot instance savings

## 🆘 **Troubleshooting**

### **Common Issues**

#### **Pod Scheduling Issues**
```bash
# Check pod events
kubectl describe pod my-pod

# Check node capacity
kubectl describe nodes
```

#### **Karpenter Issues**
```bash
# Check Karpenter logs
kubectl logs -n karpenter deployment/karpenter

# Check NodePool status
kubectl describe nodepool cost-optimized
```

#### **Network Issues**
```bash
# Check network policies
kubectl get networkpolicies

# Check service endpoints
kubectl get endpoints
```

### **Debug Commands**
```bash
# Cluster info
kubectl cluster-info

# Node status
kubectl get nodes -o wide

# Pod status
kubectl get pods -A

# Service status
kubectl get services -A
```

## 📋 **Operational Checklist**

### **Daily**
- [ ] Check cluster health
- [ ] Monitor resource usage
- [ ] Review alerts

### **Weekly**
- [ ] Review cost optimization
- [ ] Check security updates
- [ ] Monitor scaling patterns

### **Monthly**
- [ ] Update components
- [ ] Review access permissions
- [ ] Backup verification

---

**Last Updated**: December 2024  
**Version**: 3.0.0  
**Maintainer**: DevOps Team
