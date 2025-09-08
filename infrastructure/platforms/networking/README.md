# 🌐 Networking Platform

## 🎯 **Overview**

The networking platform provides essential networking components for the MSDP platform, including ingress controllers, DNS management, and certificate management.

## 🏗️ **Architecture**

```
Networking Platform
├── nginx-ingress/              # NGINX Ingress Controller
│   ├── namespace.yaml         # Ingress namespace
│   ├── helm-values.yaml       # NGINX Ingress configuration
│   └── kustomization.yaml     # Kustomize configuration
├── cert-manager/              # Certificate management
│   ├── namespace.yaml         # Cert-Manager namespace
│   ├── helm-values.yaml       # Cert-Manager configuration
│   ├── letsencrypt-issuer.yaml # Let's Encrypt issuers
│   └── kustomization.yaml     # Kustomize configuration
└── external-dns/              # DNS management
    ├── namespace.yaml         # External DNS namespace
    ├── rbac.yaml             # RBAC permissions
    ├── deployment.yaml       # External DNS controller
    ├── service.yaml          # Service configuration
    ├── servicemonitor.yaml   # Monitoring configuration
    ├── example-ingress.yaml  # Usage examples
    ├── kustomization.yaml    # Kustomize configuration
    └── README.md             # External DNS documentation
```

## 🚀 **Components**

### **1. NGINX Ingress Controller**
- **Purpose**: Provides HTTP/HTTPS ingress to services
- **Features**: Load balancing, SSL termination, path-based routing
- **Configuration**: Production-ready with security hardening
- **Monitoring**: Prometheus metrics and health checks

### **2. Cert-Manager**
- **Purpose**: Automatic SSL/TLS certificate management
- **Features**: Let's Encrypt integration, automatic renewal
- **Issuers**: Production and staging Let's Encrypt issuers
- **Monitoring**: Prometheus metrics and health checks

### **3. External DNS**
- **Purpose**: Automatic DNS record management in Route53
- **Features**: Service and ingress-based DNS record creation
- **Integration**: AWS Route53 with TXT record ownership
- **Monitoring**: Prometheus metrics and health checks

## 🔧 **Configuration**

### **NGINX Ingress Controller**
```yaml
# Key configuration features:
- LoadBalancer service with AWS NLB
- SSL/TLS termination with modern ciphers
- Rate limiting and security headers
- Prometheus metrics integration
- Health checks and resource limits
```

### **Cert-Manager**
```yaml
# Key configuration features:
- Let's Encrypt production and staging issuers
- HTTP01 challenge with NGINX ingress
- Automatic certificate renewal
- Prometheus metrics integration
- Security hardening with non-root user
```

### **External DNS**
```yaml
# Key configuration features:
- Route53 provider with batch processing
- Domain filters for aztech-msdp.com
- TXT record ownership tracking
- Prometheus metrics integration
- Health checks and resource limits
```

## 🚀 **Deployment**

### **Deploy All Networking Components**
```bash
# Deploy NGINX Ingress Controller
kubectl apply -k infrastructure/platforms/networking/nginx-ingress/

# Deploy Cert-Manager
kubectl apply -k infrastructure/platforms/networking/cert-manager/

# Deploy External DNS
kubectl apply -k infrastructure/platforms/networking/external-dns/
```

### **Verify Deployment**
```bash
# Check NGINX Ingress Controller
kubectl get pods -n ingress-nginx
kubectl get svc -n ingress-nginx

# Check Cert-Manager
kubectl get pods -n cert-manager
kubectl get clusterissuer

# Check External DNS
kubectl get pods -n external-dns
kubectl get svc -n external-dns
```

## 📝 **Usage**

### **Application Ingress**
Applications should define their own ingress manifests in their respective directories:

```yaml
# Example: infrastructure/applications/argocd/ingress/
apiVersion: networking.k8s.io/v1
kind: Ingress
metadata:
  name: argocd-ingress
  namespace: argocd
  annotations:
    # External DNS annotation
    external-dns.alpha.kubernetes.io/hostname: "argocd.dev.aztech-msdp.com"
    # Cert-Manager annotation
    cert-manager.io/cluster-issuer: "letsencrypt-prod"
    # NGINX annotations
    nginx.ingress.kubernetes.io/ssl-redirect: "true"
spec:
  ingressClassName: nginx
  tls:
    - hosts:
        - argocd.dev.aztech-msdp.com
      secretName: argocd-tls
  rules:
    - host: argocd.dev.aztech-msdp.com
      http:
        paths:
          - path: /
            pathType: Prefix
            backend:
              service:
                name: argocd-server
                port:
                  number: 80
```

### **Service with External DNS**
```yaml
apiVersion: v1
kind: Service
metadata:
  name: my-app-service
  annotations:
    external-dns.alpha.kubernetes.io/hostname: "myapp.dev.aztech-msdp.com"
spec:
  # ... service spec
```

## 🔍 **Monitoring**

### **NGINX Ingress Controller**
- **Metrics**: Available at `/metrics` endpoint
- **Health**: Liveness and readiness probes
- **Logs**: Structured JSON logging

### **Cert-Manager**
- **Metrics**: Available at `/metrics` endpoint
- **Health**: Liveness and readiness probes
- **Certificates**: Monitor certificate status and renewal

### **External DNS**
- **Metrics**: Available at `/metrics` endpoint
- **Health**: Liveness and readiness probes
- **DNS Records**: Monitor Route53 record creation and updates

## 🛡️ **Security**

### **NGINX Ingress Controller**
- **Security Headers**: Automatic security header injection
- **SSL/TLS**: Modern cipher suites and protocols
- **Rate Limiting**: Configurable rate limiting
- **Non-root User**: Runs as non-root user

### **Cert-Manager**
- **Non-root User**: Runs as non-root user
- **Read-only Filesystem**: Security hardening
- **RBAC**: Minimal required permissions

### **External DNS**
- **Non-root User**: Runs as non-root user
- **Read-only Filesystem**: Security hardening
- **RBAC**: Minimal required permissions

## 🔧 **Troubleshooting**

### **NGINX Ingress Controller**
```bash
# Check controller logs
kubectl logs -n ingress-nginx deployment/ingress-nginx-controller

# Check ingress status
kubectl describe ingress <ingress-name>

# Check service endpoints
kubectl get endpoints -n ingress-nginx
```

### **Cert-Manager**
```bash
# Check cert-manager logs
kubectl logs -n cert-manager deployment/cert-manager

# Check certificate status
kubectl describe certificate <cert-name>

# Check certificate requests
kubectl get certificaterequests
```

### **External DNS**
```bash
# Check external-dns logs
kubectl logs -n external-dns deployment/external-dns

# Check DNS records
aws route53 list-resource-record-sets --hosted-zone-id ZONE_ID

# Test DNS resolution
nslookup myapp.dev.aztech-msdp.com
```

## 🎯 **Integration with MSDP Platform**

### **Application Integration**
- **ArgoCD**: Ingress manifests in `infrastructure/applications/argocd/ingress/`
- **Backstage**: Ingress template in `infrastructure/applications/backstage/templates/`
- **Crossplane**: Ingress manifests in `infrastructure/applications/crossplane/`

### **Environment-Specific Configuration**
- **Dev**: `*.dev.aztech-msdp.com`
- **Test**: `*.test.aztech-msdp.com`
- **Prod**: `*.prod.aztech-msdp.com`

### **Platform Services**
- **ArgoCD**: `argocd.dev.aztech-msdp.com`
- **Backstage**: `backstage.dev.aztech-msdp.com`
- **Applications**: `*.dev.aztech-msdp.com`

## 📊 **Benefits**

### **✅ Centralized Networking**
- **Single ingress controller** for all applications
- **Centralized certificate management** with automatic renewal
- **Automatic DNS management** with Route53 integration

### **✅ Security & Compliance**
- **SSL/TLS termination** with modern security standards
- **Automatic certificate renewal** with Let's Encrypt
- **Security headers** and rate limiting

### **✅ Monitoring & Observability**
- **Prometheus metrics** for all components
- **Health checks** and readiness probes
- **Structured logging** for troubleshooting

### **✅ Application Integration**
- **Application-specific ingress** manifests
- **Environment-specific domains** and certificates
- **Automatic DNS record creation** and management

---

**The networking platform provides a robust, secure, and scalable foundation for all MSDP platform applications.** 🌐
# Platform Components Deployment Test - Mon Sep  8 03:23:41 BST 2025
