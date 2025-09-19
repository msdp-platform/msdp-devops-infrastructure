# Unified Domain Architecture with aztech-msdp.com

## 🎯 **Updated Architecture Overview**

Perfect! Your unified domain approach with `aztech-msdp.com` and Route53 is much better. Here's how everything works with your registered domain and single load balancer architecture.

## 🌐 **Domain & DNS Architecture**

### **Unified Domain Strategy**
- **Domain**: `aztech-msdp.com` (registered public domain)
- **DNS Provider**: AWS Route53 (for ALL environments)
- **Hosted Zone ID**: `Z0581458B5QGVNLDPESN`
- **Multi-Cloud**: Both AWS and Azure clusters use Route53

### **Environment Subdomains**
```
Production:  app.aztech-msdp.com
Development: app-dev.aztech-msdp.com
Staging:     app-staging.aztech-msdp.com
```

## 🔐 **Certificate Storage & Management**

### **How Certificates are Stored**

**1. Kubernetes Secrets (Primary Storage)**
```yaml
apiVersion: v1
kind: Secret
metadata:
  name: abc-app-tls
  namespace: default
type: kubernetes.io/tls
data:
  tls.crt: <base64-encoded-certificate>
  tls.key: <base64-encoded-private-key>
```

**2. Certificate Lifecycle**
```
1. Ingress Created → 2. Cert-Manager Detects → 3. DNS Challenge → 4. Certificate Issued → 5. Stored in Secret
```

**3. Storage Locations**
- **Primary**: Kubernetes etcd (encrypted at rest)
- **Backup**: Automatic backup via Velero
- **Replication**: Across all master nodes in the cluster

### **How Certificates are Attached to Ingress**

**Method 1: Automatic (Recommended)**
```yaml
apiVersion: networking.k8s.io/v1
kind: Ingress
metadata:
  name: abc-app-ingress
  annotations:
    kubernetes.io/ingress.class: nginx
    cert-manager.io/cluster-issuer: letsencrypt-staging  # Auto-generates certificate
spec:
  tls:
  - hosts:
    - abc-dev.aztech-msdp.com
    secretName: abc-app-tls  # Cert-manager creates this secret automatically
  rules:
  - host: abc-dev.aztech-msdp.com
    http:
      paths:
      - path: /
        pathType: Prefix
        backend:
          service:
            name: abc-app-service
            port:
              number: 80
```

**Method 2: Manual (Pre-existing certificate)**
```yaml
apiVersion: networking.k8s.io/v1
kind: Ingress
metadata:
  name: abc-app-ingress
  annotations:
    kubernetes.io/ingress.class: nginx
spec:
  tls:
  - hosts:
    - abc-dev.aztech-msdp.com
    secretName: existing-certificate-secret  # Reference existing secret
  rules:
  - host: abc-dev.aztech-msdp.com
    http:
      paths:
      - path: /
        pathType: Prefix
        backend:
          service:
            name: abc-app-service
            port:
              number: 80
```

## 🔄 **Single Load Balancer Architecture**

### **NGINX Ingress Controller as Single Entry Point**

**Architecture Benefits:**
- ✅ **Single Load Balancer**: One cloud load balancer per cluster
- ✅ **Cost Effective**: Reduced cloud load balancer costs
- ✅ **Centralized SSL**: All certificates managed in one place
- ✅ **Advanced Routing**: Path-based, host-based, header-based routing
- ✅ **Rate Limiting**: Centralized rate limiting and security

### **Traffic Flow**
```
Internet → Cloud Load Balancer → NGINX Ingress Controller → App Services
```

**Detailed Flow:**
```
1. DNS Resolution: abc-dev.aztech-msdp.com → Load Balancer IP
2. Cloud Load Balancer: Routes to NGINX Ingress Controller pods
3. NGINX Controller: 
   - Terminates SSL using certificate from Kubernetes secret
   - Routes based on hostname/path to appropriate service
   - Applies policies (rate limiting, auth, etc.)
4. Kubernetes Service: Load balances to app pods
```

## 🏗️ **Complete Example: "abc" App Deployment**

### **Your "abc" App Access URL**
```
https://abc-dev.aztech-msdp.com
```

### **DNS Records in Route53**
```
# A Record (points to cloud load balancer)
abc-dev.aztech-msdp.com.    300    IN    A    52.208.123.45

# TXT Record (External DNS ownership)
external-dns-abc-dev.aztech-msdp.com.    300    IN    TXT    "heritage=external-dns,external-dns/owner=eks-msdp-dev-01"

# TXT Record (Let's Encrypt challenge - temporary)
_acme-challenge.abc-dev.aztech-msdp.com.    300    IN    TXT    "challenge-token-here"
```

### **Certificate Storage**
```
Secret Name: abc-app-tls
Namespace: default
Certificate: Let's Encrypt Staging (dev) / Production (prod)
Storage: Kubernetes etcd (encrypted)
```

### **Complete Deployment Manifest**
```yaml
# abc-app-complete.yaml
apiVersion: apps/v1
kind: Deployment
metadata:
  name: abc-app
  labels:
    app: abc
spec:
  replicas: 2
  selector:
    matchLabels:
      app: abc
  template:
    metadata:
      labels:
        app: abc
    spec:
      containers:
      - name: abc
        image: nginx:alpine
        ports:
        - containerPort: 80
        resources:
          requests:
            cpu: 50m
            memory: 64Mi
          limits:
            cpu: 100m
            memory: 128Mi
---
apiVersion: v1
kind: Service
metadata:
  name: abc-app-service
spec:
  selector:
    app: abc
  ports:
  - port: 80
    targetPort: 80
---
apiVersion: networking.k8s.io/v1
kind: Ingress
metadata:
  name: abc-app-ingress
  annotations:
    kubernetes.io/ingress.class: nginx
    cert-manager.io/cluster-issuer: letsencrypt-staging
    nginx.ingress.kubernetes.io/ssl-redirect: "true"
    nginx.ingress.kubernetes.io/rate-limit: "100"
spec:
  tls:
  - hosts:
    - abc-dev.aztech-msdp.com
    secretName: abc-app-tls
  rules:
  - host: abc-dev.aztech-msdp.com
    http:
      paths:
      - path: /
        pathType: Prefix
        backend:
          service:
            name: abc-app-service
            port:
              number: 80
```

## 🌍 **Multi-Cloud DNS Configuration**

### **AWS Clusters**
```yaml
external-dns:
  provider: aws
  domain_filters: ["aztech-msdp.com"]
  hosted_zone_id: "Z0581458B5QGVNLDPESN"

cert-manager:
  dns_provider: route53
  hosted_zone_id: "Z0581458B5QGVNLDPESN"
```

### **Azure Clusters**
```yaml
external-dns:
  provider: aws  # Still uses Route53!
  domain_filters: ["aztech-msdp.com"]
  hosted_zone_id: "Z0581458B5QGVNLDPESN"

cert-manager:
  dns_provider: route53  # Still uses Route53!
  hosted_zone_id: "Z0581458B5QGVNLDPESN"
```

### **Required Permissions**

**AWS Clusters**: Native Route53 access via IAM roles

**Azure Clusters**: Need AWS credentials for Route53 access
```yaml
# Azure cluster needs AWS credentials as Kubernetes secret
apiVersion: v1
kind: Secret
metadata:
  name: aws-credentials
  namespace: external-dns-system
type: Opaque
data:
  aws-access-key-id: <base64-encoded>
  aws-secret-access-key: <base64-encoded>
```

## 🔍 **Certificate Management Deep Dive**

### **Certificate Lifecycle**

**1. Certificate Request**
```yaml
apiVersion: cert-manager.io/v1
kind: Certificate
metadata:
  name: abc-app-certificate
  namespace: default
spec:
  secretName: abc-app-tls
  issuerRef:
    name: letsencrypt-staging
    kind: ClusterIssuer
  dnsNames:
  - abc-dev.aztech-msdp.com
```

**2. DNS Challenge Process**
```
1. Cert-manager creates CertificateRequest
2. ACME client contacts Let's Encrypt
3. Let's Encrypt provides DNS challenge
4. Cert-manager creates TXT record in Route53
5. Let's Encrypt validates TXT record
6. Certificate issued and stored in Kubernetes secret
7. TXT record cleaned up
```

**3. Certificate Storage Structure**
```yaml
apiVersion: v1
kind: Secret
metadata:
  name: abc-app-tls
  namespace: default
  annotations:
    cert-manager.io/certificate-name: abc-app-certificate
    cert-manager.io/issuer-name: letsencrypt-staging
    cert-manager.io/issuer-kind: ClusterIssuer
type: kubernetes.io/tls
data:
  tls.crt: LS0tLS1CRUdJTi... # Base64 encoded certificate
  tls.key: LS0tLS1CRUdJTi... # Base64 encoded private key
```

## 🎯 **Environment-Specific URLs**

### **Development Environment**
```
Apps:     https://abc-dev.aztech-msdp.com
Grafana:  https://grafana-dev.aztech-msdp.com
ArgoCD:   https://argocd-dev.aztech-msdp.com
Jaeger:   https://jaeger-dev.aztech-msdp.com
```

### **Production Environment**
```
Apps:     https://abc.aztech-msdp.com
Grafana:  https://grafana.aztech-msdp.com
ArgoCD:   https://argocd.aztech-msdp.com
Jaeger:   https://jaeger.aztech-msdp.com
```

## 🛡️ **Security & Best Practices**

### **Certificate Security**
- ✅ **Encryption at Rest**: Kubernetes secrets encrypted in etcd
- ✅ **RBAC**: Restricted access to certificate secrets
- ✅ **Automatic Renewal**: 60 days before expiry
- ✅ **Backup**: Certificates backed up via Velero

### **DNS Security**
- ✅ **Ownership Validation**: TXT records for ownership proof
- ✅ **Access Control**: IAM roles for Route53 access
- ✅ **Audit Trail**: All DNS changes logged

### **Load Balancer Security**
- ✅ **SSL Termination**: At NGINX Ingress Controller
- ✅ **Security Headers**: Automatic security headers
- ✅ **Rate Limiting**: Per-host rate limiting
- ✅ **DDoS Protection**: Cloud provider DDoS protection

## 🚀 **Deployment Commands**

### **Deploy Your "abc" App**
```bash
kubectl apply -f abc-app-complete.yaml
```

### **Check Certificate Status**
```bash
kubectl get certificate abc-app-certificate
kubectl describe certificate abc-app-certificate
```

### **Check DNS Records**
```bash
nslookup abc-dev.aztech-msdp.com
dig abc-dev.aztech-msdp.com
```

### **Access Your App**
```bash
curl -k https://abc-dev.aztech-msdp.com
# Note: -k flag needed for staging certificates
```

## 🎉 **Summary**

With your `aztech-msdp.com` domain and unified Route53 approach:

- ✅ **Single Domain**: All environments use aztech-msdp.com
- ✅ **Centralized DNS**: Route53 manages all DNS records
- ✅ **Single Load Balancer**: NGINX Ingress Controller per cluster
- ✅ **Automatic Certificates**: Cert-manager handles all SSL certificates
- ✅ **Multi-Cloud**: Works seamlessly on both AWS and Azure
- ✅ **Cost Effective**: Minimal cloud load balancer costs
- ✅ **Production Ready**: Enterprise-grade security and monitoring

**Your "abc" app will be accessible at `https://abc-dev.aztech-msdp.com` with automatic DNS and SSL certificate management!** 🎯