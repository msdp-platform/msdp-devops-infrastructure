# Single Public IP Setup Guide

## Overview

This guide covers the setup of a cost-optimized single public IP solution using NGINX Ingress Controller to expose all services through one LoadBalancer instead of multiple LoadBalancers.

## Architecture

```
┌─────────────────────────────────────────────────────────────┐
│                    Internet                                 │
└─────────────────────┬───────────────────────────────────────┘
                      │
┌─────────────────────▼───────────────────────────────────────┐
│              Azure LoadBalancer                             │
│              (Single Public IP)                             │
└─────────────────────┬───────────────────────────────────────┘
                      │
┌─────────────────────▼───────────────────────────────────────┐
│              NGINX Ingress Controller                       │
│              (Path-based routing)                           │
└─────────────────────┬───────────────────────────────────────┘
                      │
        ┌─────────────┼─────────────┐
        │             │             │
┌───────▼──────┐ ┌───▼────┐ ┌──────▼──────┐
│   ArgoCD     │ │Crossplane│ │ Sample App  │
│   (ClusterIP)│ │(ClusterIP)│ │ (ClusterIP) │
└──────────────┘ └────────┘ └─────────────┘
```

## Cost Optimization

### Before (Multiple LoadBalancers)
- ArgoCD LoadBalancer: ~$18/month
- Crossplane LoadBalancer: ~$18/month  
- Sample App LoadBalancer: ~$18/month
- **Total: ~$54/month**

### After (Single LoadBalancer)
- NGINX Ingress LoadBalancer: ~$18/month
- **Total: ~$18/month**
- **Savings: ~$36/month (67% reduction)**

## Setup Components

### 1. NGINX Ingress Controller
```bash
# Install NGINX Ingress Controller
helm install ingress-nginx ingress-nginx/ingress-nginx \
  --namespace ingress-nginx \
  --set controller.service.type=LoadBalancer \
  --set controller.replicaCount=1 \
  --set controller.resources.requests.cpu=100m \
  --set controller.resources.requests.memory=128Mi
```

### 2. Service Configuration
```bash
# Convert ArgoCD from LoadBalancer to ClusterIP
kubectl patch svc argocd-server -n argocd -p '{"spec": {"type": "ClusterIP"}}'
```

### 3. Ingress Rules
```yaml
# ArgoCD Ingress
apiVersion: networking.k8s.io/v1
kind: Ingress
metadata:
  name: delivery-platform-ingress
  namespace: argocd
  annotations:
    nginx.ingress.kubernetes.io/ssl-redirect: "false"
    nginx.ingress.kubernetes.io/backend-protocol: "HTTPS"
spec:
  ingressClassName: nginx
  rules:
  - host: argocd.delivery-platform.local
    http:
      paths:
      - path: /
        pathType: Prefix
        backend:
          service:
            name: argocd-server
            port:
              number: 443
```

## Service Access

### Public IP
- **Current IP**: `52.170.163.40` (may change)
- **Check IP**: `kubectl get svc -n ingress-nginx ingress-nginx-controller -o jsonpath='{.status.loadBalancer.ingress[0].ip}'`

### Service URLs
- **ArgoCD**: `http://argocd.delivery-platform.local`
- **Crossplane**: `http://crossplane.delivery-platform.local`
- **Sample App**: `http://app.delivery-platform.local`

### Local DNS Setup
```bash
# Add to /etc/hosts
echo "52.170.163.40 argocd.delivery-platform.local" | sudo tee -a /etc/hosts
echo "52.170.163.40 crossplane.delivery-platform.local" | sudo tee -a /etc/hosts
echo "52.170.163.40 app.delivery-platform.local" | sudo tee -a /etc/hosts
```

## Management Scripts

### Cost Optimization Summary
```bash
./scripts/cost-optimization-summary.sh
```

### Local DNS Setup
```bash
./scripts/setup-local-dns.sh
```

### ArgoCD Access
```bash
./scripts/argocd-access.sh status
```

## Troubleshooting

### Check Ingress Status
```bash
kubectl get ingress --all-namespaces
kubectl describe ingress -n argocd delivery-platform-ingress
```

### Check Ingress Controller Logs
```bash
kubectl logs -n ingress-nginx -l app.kubernetes.io/name=ingress-nginx
```

### Test Connectivity
```bash
# Test from within cluster
kubectl run test-pod --image=nginx --rm -it --restart=Never -- curl -I http://argocd-server.argocd.svc.cluster.local

# Test public IP
curl -I http://52.170.163.40
```

### Common Issues

1. **LoadBalancer IP Changes**
   - Azure may assign new IPs
   - Update /etc/hosts with new IP
   - Check with: `kubectl get svc -n ingress-nginx`

2. **Network Connectivity**
   - Check Azure NSG rules
   - Verify LoadBalancer configuration
   - Test from within cluster first

3. **Ingress Not Working**
   - Check ingress controller logs
   - Verify service endpoints
   - Check ingress rules syntax

## Benefits Achieved

✅ **67% cost reduction** on LoadBalancers
✅ **Single public IP** for all services
✅ **Simplified network management**
✅ **Better security** with ingress rules
✅ **Easy SSL termination** (future enhancement)
✅ **Path-based routing**
✅ **Rate limiting capabilities** (future enhancement)

## Future Enhancements

1. **SSL/TLS Certificates**
   - Use cert-manager for automatic certificates
   - Enable HTTPS for all services

2. **Advanced Features**
   - Rate limiting
   - DDoS protection
   - Web Application Firewall (WAF)

3. **Azure Application Gateway**
   - More advanced features
   - Better integration with Azure services
   - Enhanced security

4. **CDN Integration**
   - Azure CDN for static content
   - Global content delivery
   - Reduced latency

## Monitoring

### Check Resource Usage
```bash
kubectl top nodes
kubectl top pods -n ingress-nginx
```

### Monitor Costs
```bash
./scripts/aks-cost-monitor.sh status
```

### Check Service Health
```bash
kubectl get pods --all-namespaces
kubectl get svc --all-namespaces
```

## Security Considerations

1. **Network Security Groups**
   - Restrict access to necessary ports
   - Use Azure NSG rules

2. **Ingress Security**
   - Implement rate limiting
   - Add authentication
   - Use HTTPS

3. **Service Security**
   - Keep services as ClusterIP
   - Use RBAC for access control
   - Implement network policies

This setup provides a cost-effective, scalable solution for exposing multiple services through a single public IP while maintaining security and performance.
