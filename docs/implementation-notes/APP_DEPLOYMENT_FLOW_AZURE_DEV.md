# App Deployment Flow: "abc" App in Azure Dev Environment

## 🎯 **Scenario: Deploying App "abc" in Azure Dev**

Based on your configuration, here's exactly what happens when you deploy an app called "abc" in your Azure dev environment.

## 🌐 **Your Access URL**

### **Primary Access URL**
```
https://abc-dev.msdp.io
```

### **Alternative URLs (if configured)**
```
https://abc.dev.msdp.io
https://dev-abc.msdp.io
```

## 📋 **Complete Deployment Flow**

### **1. App Deployment with Ingress**
When you deploy your "abc" app, you'll create an Ingress resource like this:

```yaml
apiVersion: networking.k8s.io/v1
kind: Ingress
metadata:
  name: abc-app-ingress
  namespace: default
  annotations:
    kubernetes.io/ingress.class: nginx
    cert-manager.io/cluster-issuer: letsencrypt-staging
    nginx.ingress.kubernetes.io/ssl-redirect: "true"
spec:
  tls:
  - hosts:
    - abc-dev.msdp.io
    secretName: abc-app-tls
  rules:
  - host: abc-dev.msdp.io
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

### **2. Automatic DNS Record Creation**

**🔍 Where:** Your DNS records will be created in **Azure DNS** (not AWS Route53)

**📍 DNS Zone:** `dev.msdp.io` (hosted in Azure DNS)

**📝 Records Created:**
```
# A Record (points to Azure Load Balancer IP)
abc-dev.msdp.io.    300    IN    A    20.90.123.45

# TXT Record (for External DNS ownership)
external-dns-abc-dev.msdp.io.    300    IN    TXT    "heritage=external-dns,external-dns/owner=aks-msdp-dev-01"
```

**🏗️ Azure Resources:**
- **DNS Zone**: `dev.msdp.io` in resource group `rg-msdp-network-dev`
- **Load Balancer**: Azure Load Balancer with public IP
- **Public IP**: Assigned to the NGINX Ingress Controller service

### **3. Certificate Management**

**🔐 Certificate Storage Location:**
```
Kubernetes Secret: abc-app-tls
Namespace: default (or your app's namespace)
Type: kubernetes.io/tls
```

**📜 Certificate Details:**
- **Issuer**: Let's Encrypt Staging (for dev environment)
- **Challenge Type**: DNS-01 (using Azure DNS)
- **Validation**: Automatic via cert-manager
- **Renewal**: Automatic (60 days before expiry)

**🔄 Certificate Creation Process:**
1. **Cert-Manager** detects the Ingress with `cert-manager.io/cluster-issuer` annotation
2. Creates a **Certificate** resource automatically
3. Initiates **DNS-01 challenge** with Let's Encrypt Staging
4. Creates **TXT record** in Azure DNS for validation: `_acme-challenge.abc-dev.msdp.io`
5. Let's Encrypt validates the challenge
6. Certificate is issued and stored in Kubernetes Secret `abc-app-tls`
7. NGINX Ingress Controller uses the certificate for TLS termination

## 🏗️ **Infrastructure Components Involved**

### **Azure Resources**
```
📍 Resource Group: rg-msdp-network-dev
├── 🌐 DNS Zone: dev.msdp.io
│   ├── A Record: abc-dev.msdp.io → 20.90.123.45
│   └── TXT Records: external-dns ownership + ACME challenges
├── 🔗 Load Balancer: NGINX Ingress Controller LB
├── 📍 Public IP: Assigned to Load Balancer
└── 🏗️ AKS Cluster: aks-msdp-dev-01
```

### **Kubernetes Resources**
```
🎪 Cluster: aks-msdp-dev-01
├── 🔌 NGINX Ingress Controller (nginx-ingress namespace)
├── 🔐 Cert-Manager (cert-manager namespace)
├── 🌐 External DNS (external-dns-system namespace)
└── 📱 Your App Resources (default namespace)
    ├── Deployment: abc-app
    ├── Service: abc-app-service
    ├── Ingress: abc-app-ingress
    └── Secret: abc-app-tls (certificate)
```

## 🔄 **Step-by-Step Flow**

### **Step 1: Deploy Your App**
```bash
kubectl apply -f abc-app-deployment.yaml
kubectl apply -f abc-app-service.yaml
kubectl apply -f abc-app-ingress.yaml
```

### **Step 2: External DNS Creates DNS Record**
```
⏱️ ~30 seconds after Ingress creation
📍 Location: Azure DNS Zone "dev.msdp.io"
📝 Record: abc-dev.msdp.io → Azure Load Balancer IP
```

### **Step 3: Cert-Manager Requests Certificate**
```
⏱️ ~1-2 minutes after Ingress creation
🔐 Process: DNS-01 challenge with Let's Encrypt Staging
📍 Validation: TXT record in Azure DNS
⏳ Duration: 2-5 minutes for certificate issuance
```

### **Step 4: App Becomes Accessible**
```
⏱️ ~3-5 minutes total
🌐 URL: https://abc-dev.msdp.io
🔒 Certificate: Let's Encrypt Staging (browser warning expected)
```

## 🔍 **Verification Commands**

### **Check DNS Resolution**
```bash
# Check if DNS record exists
nslookup abc-dev.msdp.io

# Check from external DNS controller
kubectl logs -n external-dns-system -l app.kubernetes.io/name=external-dns
```

### **Check Certificate Status**
```bash
# Check certificate resource
kubectl get certificate abc-app-tls

# Check certificate details
kubectl describe certificate abc-app-tls

# Check certificate secret
kubectl get secret abc-app-tls -o yaml
```

### **Check Ingress Status**
```bash
# Check ingress resource
kubectl get ingress abc-app-ingress

# Check ingress controller logs
kubectl logs -n nginx-ingress -l app.kubernetes.io/name=ingress-nginx
```

## 🌍 **Multi-Cloud DNS Architecture**

### **Important Note: DNS Hosting**
Based on your configuration:

- **Azure Dev Environment**: DNS hosted in **Azure DNS** (`dev.msdp.io`)
- **AWS Environment**: DNS would be hosted in **AWS Route53**
- **No Cross-Cloud DNS**: Each cloud manages its own DNS zone

### **If You Want Cross-Cloud DNS**
To have AWS Route53 manage DNS for Azure apps, you'd need to:

1. **Update Azure config** to use AWS Route53:
```yaml
external-dns:
  config:
    provider: aws  # Change from azure to aws
    aws_region: eu-west-1
    domain_filters: ["dev.msdp.io"]
```

2. **Configure AWS credentials** in Azure AKS for Route53 access

## 🎯 **Production vs Development**

### **Development Environment (Current)**
- **Certificate**: Let's Encrypt **Staging** (browser warning)
- **DNS**: `dev.msdp.io` domain
- **Access**: `https://abc-dev.msdp.io`

### **Production Environment (When Deployed)**
- **Certificate**: Let's Encrypt **Production** (trusted)
- **DNS**: `prod.msdp.io` or `msdp.io` domain
- **Access**: `https://abc.msdp.io` or `https://abc-prod.msdp.io`

## 🚀 **Quick Test Deployment**

Here's a complete example to test with your "abc" app:

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
spec:
  tls:
  - hosts:
    - abc-dev.msdp.io
    secretName: abc-app-tls
  rules:
  - host: abc-dev.msdp.io
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

## 📋 **Summary**

**Your "abc" app in Azure dev will be accessible at:**
- 🌐 **URL**: `https://abc-dev.msdp.io`
- 📍 **DNS**: Azure DNS zone `dev.msdp.io` in `rg-msdp-network-dev`
- 🔐 **Certificate**: Kubernetes Secret `abc-app-tls` (Let's Encrypt Staging)
- ⏱️ **Ready in**: ~3-5 minutes after deployment

The entire process is **fully automated** thanks to your pluggable add-ons system! 🎉