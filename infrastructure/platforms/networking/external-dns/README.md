# 🌐 External DNS Controller for Route53

## 🎯 **Overview**

External DNS controller automatically manages DNS records in AWS Route53 based on Kubernetes services and ingresses. This enables automatic DNS record creation and management for the MSDP platform.

## 🏗️ **Architecture**

```
Kubernetes Cluster
├── Services/Ingresses (with annotations)
├── External DNS Controller
│   ├── Watches Kubernetes resources
│   ├── Creates/Updates Route53 records
│   └── Manages DNS synchronization
└── AWS Route53
    ├── aztech-msdp.com
    ├── dev.aztech-msdp.com
    ├── test.aztech-msdp.com
    └── prod.aztech-msdp.com
```

## 📁 **Configuration Files**

### **Core Components**
- **`namespace.yaml`** - External DNS namespace
- **`rbac.yaml`** - Service account and RBAC permissions
- **`deployment.yaml`** - External DNS controller deployment
- **`service.yaml`** - Service for health checks and monitoring
- **`servicemonitor.yaml`** - Prometheus monitoring configuration

## 🔧 **Configuration Details**

### **Domain Filters**
```yaml
- --domain-filter=aztech-msdp.com
- --domain-filter=dev.aztech-msdp.com
- --domain-filter=test.aztech-msdp.com
- --domain-filter=prod.aztech-msdp.com
```

### **AWS Configuration**
```yaml
- --provider=aws
- --aws-zone-type=public
- --aws-prefer-cname
- --aws-batch-change-size=1000
- --aws-batch-change-interval=10s
```

### **Registry Settings**
```yaml
- --registry=txt
- --txt-owner-id=external-dns
- --txt-prefix=external-dns-
```

## 🚀 **Deployment**

### **Prerequisites**
1. **AWS Credentials**: Configured via IAM roles or secrets
2. **Route53 Hosted Zones**: Created for all domains
3. **IAM Permissions**: External DNS service account needs Route53 permissions

### **Deploy External DNS**
```bash
# Apply all External DNS configurations
kubectl apply -f infrastructure/platforms/networking/external-dns/

# Verify deployment
kubectl get pods -n external-dns
kubectl get svc -n external-dns
```

## 📝 **Usage**

### **Service Annotations**
```yaml
apiVersion: v1
kind: Service
metadata:
  name: my-service
  annotations:
    external-dns.alpha.kubernetes.io/hostname: myapp.dev.aztech-msdp.com
spec:
  # ... service spec
```

### **Ingress Annotations**
```yaml
apiVersion: networking.k8s.io/v1
kind: Ingress
metadata:
  name: my-ingress
  annotations:
    external-dns.alpha.kubernetes.io/hostname: myapp.dev.aztech-msdp.com
spec:
  # ... ingress spec
```

## 🔍 **Monitoring**

### **Health Checks**
- **Liveness Probe**: `/healthz` endpoint
- **Readiness Probe**: `/healthz` endpoint
- **Metrics**: Available at `/metrics` endpoint

### **Prometheus Integration**
```yaml
# ServiceMonitor automatically scrapes metrics
apiVersion: monitoring.coreos.com/v1
kind: ServiceMonitor
metadata:
  name: external-dns
  namespace: external-dns
```

## 🛡️ **Security**

### **RBAC Permissions**
- **Services**: get, watch, list
- **Endpoints**: get, watch, list
- **Pods**: get, watch, list
- **Ingresses**: get, watch, list
- **Nodes**: list, watch
- **Route53 Resources**: full access

### **Security Context**
```yaml
securityContext:
  allowPrivilegeEscalation: false
  capabilities:
    drop:
    - ALL
  readOnlyRootFilesystem: true
  runAsNonRoot: true
  runAsUser: 65534
```

## 🔧 **Troubleshooting**

### **Check External DNS Logs**
```bash
kubectl logs -n external-dns deployment/external-dns
```

### **Verify DNS Records**
```bash
# Check Route53 records
aws route53 list-resource-record-sets --hosted-zone-id ZONE_ID

# Test DNS resolution
nslookup myapp.dev.aztech-msdp.com
```

### **Common Issues**
1. **AWS Credentials**: Ensure proper IAM permissions
2. **Domain Filters**: Verify domain filters match your domains
3. **Annotations**: Check service/ingress annotations
4. **Route53 Zones**: Ensure hosted zones exist

## 📊 **Metrics**

### **Available Metrics**
- `external_dns_registry_errors_total`
- `external_dns_source_errors_total`
- `external_dns_aws_route53_requests_total`
- `external_dns_aws_route53_errors_total`

### **Grafana Dashboard**
- External DNS performance metrics
- Route53 API call statistics
- Error rates and success rates

## 🎯 **Integration with MSDP Platform**

### **Automatic DNS Management**
- **ArgoCD**: `argocd.dev.aztech-msdp.com`
- **Backstage**: `backstage.dev.aztech-msdp.com`
- **Applications**: `*.dev.aztech-msdp.com`

### **Environment-Specific Domains**
- **Dev**: `*.dev.aztech-msdp.com`
- **Test**: `*.test.aztech-msdp.com`
- **Prod**: `*.prod.aztech-msdp.com`

## 🔄 **Workflow**

1. **Service/Ingress Created** → External DNS detects change
2. **DNS Record Creation** → External DNS creates Route53 record
3. **TXT Record** → External DNS creates ownership TXT record
4. **DNS Propagation** → Route53 propagates DNS changes
5. **Health Monitoring** → External DNS monitors and updates records

---

**External DNS controller provides automatic DNS management for the MSDP platform, ensuring seamless integration with AWS Route53.** 🌐
