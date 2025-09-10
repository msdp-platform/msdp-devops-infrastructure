# 🚀 Comprehensive EKS Platform Setup Guide

## 📋 **Overview**

This guide walks you through setting up a comprehensive EKS platform with all the components you requested. The platform includes everything needed for a production-ready Kubernetes environment with cost optimization, security, observability, and GitOps capabilities.

## 🎯 **What You'll Get**

### **Core EKS Cluster Components**
- **EKS Cluster** with managed node groups
- **Fargate Profiles** for serverless workloads
- **VPC CNI** for advanced networking

### **Security & Governance**
- **AWS Load Balancer Controller** (ALB/NLB ingress)
- **External DNS** (auto-manage Route 53 DNS records)
- **Cert-Manager** (TLS cert automation with ACM)
- **Secrets Store CSI Driver** (integrates with AWS Secrets Manager & SSM Parameter Store)
- **Karpenter** (intelligent autoscaling, ARM-based spot instance optimization)

### **Networking & Traffic Management**
- **Amazon VPC CNI** (default networking)
- **NGINX Ingress Controller** (popular ingress option)

### **Observability (Monitoring & Logging)**
- **Prometheus + Alertmanager** (metrics + alerting)
- **Grafana** (dashboards, often with AWS Managed Grafana)

### **CI/CD & GitOps**
- **ArgoCD** (GitOps controller, deploy workloads via Git)
- **AWS Controllers for Kubernetes (ACK)**

### **Others**
- **Crossplane** (Infrastructure as Code)
- **Backstage** (Developer portal)

## 📋 **Prerequisites**

### **1. AWS Account Setup**
- AWS account with appropriate permissions
- AWS CLI configured
- Terraform >= 1.0 installed
- kubectl >= 1.28 installed
- Helm >= 3.13 installed

### **2. Required AWS Permissions**
Your AWS user/role needs these permissions:
```json
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Action": [
        "eks:*",
        "ec2:*",
        "iam:*",
        "vpc:*",
        "sqs:*",
        "events:*",
        "cloudwatch:*",
        "logs:*",
        "route53:*",
        "acm:*",
        "secretsmanager:*",
        "ssm:*"
      ],
      "Resource": "*"
    }
  ]
}
```

### **3. GitHub Repository Setup**
- GitHub repository with Actions enabled
- GitHub secrets configured (see below)

## 🔧 **Step-by-Step Setup**

### **Step 1: Configure GitHub Secrets**

Go to your GitHub repository → Settings → Secrets and variables → Actions, and add:

```bash
AWS_ACCESS_KEY_ID=your-access-key-id
AWS_SECRET_ACCESS_KEY=your-secret-access-key
```

### **Step 2: Customize Configuration**

1. **Copy the example variables file**:
   ```bash
   cd infrastructure/terraform/environments/dev
   cp terraform.tfvars.example terraform.tfvars
   ```

2. **Edit terraform.tfvars** with your values:
   ```hcl
   cluster_name = "your-cluster-name"
   aws_region   = "your-preferred-region"
   vpc_cidr     = "10.0.0.0/16"
   
   # DNS Configuration
   domain_name = "your-domain.com"
   create_route53_zone = true
   create_acm_certificate = true
   letsencrypt_email = "admin@your-domain.com"
   
   # Add your AWS users for cluster access
   aws_auth_users = [
     {
       userarn  = "arn:aws:iam::YOUR-ACCOUNT:user/your-username"
       username = "your-username"
       groups   = ["system:masters"]
     }
   ]
   ```

### **Step 3: Deploy Infrastructure**

#### **Option A: Deploy via GitHub Actions (Recommended)**

1. **Push to dev branch**:
   ```bash
   git add .
   git commit -m "Comprehensive EKS platform setup"
   git push origin dev
   ```

2. **Monitor the deployment** in GitHub Actions tab

3. **Or use manual deployment**:
   - Go to Actions → Deploy EKS with Karpenter
   - Click "Run workflow"
   - Select environment: `dev`
   - Select action: `apply`

#### **Option B: Deploy Locally**

1. **Initialize Terraform**:
   ```bash
   cd infrastructure/terraform/environments/dev
   terraform init
   ```

2. **Plan the deployment**:
   ```bash
   terraform plan
   ```

3. **Apply the configuration**:
   ```bash
   terraform apply
   ```

### **Step 4: Configure kubectl**

After deployment, configure kubectl to access your cluster:

```bash
aws eks update-kubeconfig --region us-west-2 --name your-cluster-name
```

### **Step 5: Verify All Components**

1. **Check cluster status**:
   ```bash
   kubectl get nodes
   kubectl get pods --all-namespaces
   ```

2. **Verify Karpenter**:
   ```bash
   kubectl get pods -n karpenter
   kubectl get nodepools
   kubectl get nodeclasses
   ```

3. **Check all platform components**:
   ```bash
   # AWS Load Balancer Controller
   kubectl get pods -n kube-system -l app.kubernetes.io/name=aws-load-balancer-controller
   
   # External DNS
   kubectl get pods -n kube-system -l app.kubernetes.io/name=external-dns
   
   # Cert-Manager
   kubectl get pods -n cert-manager
   
   # Secrets Store CSI Driver
   kubectl get pods -n kube-system -l app=secrets-store-csi-driver
   
   # NGINX Ingress Controller
   kubectl get pods -n ingress-nginx
   
   # Prometheus & Grafana
   kubectl get pods -n monitoring
   
   # ArgoCD
   kubectl get pods -n argocd
   
   # Crossplane
   kubectl get pods -n crossplane-system
   
   # ACK Controllers
   kubectl get pods -n ack-system
   
   # Backstage
   kubectl get pods -n backstage
   ```

## 🌐 **Accessing Your Platform**

### **Service URLs**

After deployment, you can access:

- **ArgoCD**: `https://argocd.your-domain.com` (admin/admin123)
- **Backstage**: `https://backstage.your-domain.com`
- **Grafana**: `http://grafana.monitoring.svc.cluster.local:3000` (admin/admin123)
- **Prometheus**: `http://prometheus.monitoring.svc.cluster.local:9090`

### **Get Service URLs**

```bash
# ArgoCD
kubectl get svc -n argocd argocd-server

# Backstage
kubectl get svc -n backstage backstage

# Grafana
kubectl get svc -n monitoring grafana

# Prometheus
kubectl get svc -n monitoring prometheus-server
```

## 🧪 **Testing Platform Components**

### **Test 1: Karpenter Node Provisioning**

Create a test deployment to trigger Karpenter:

```bash
cat <<EOF | kubectl apply -f -
apiVersion: apps/v1
kind: Deployment
metadata:
  name: test-karpenter
  namespace: default
spec:
  replicas: 1
  selector:
    matchLabels:
      app: test-karpenter
  template:
    metadata:
      labels:
        app: test-karpenter
    spec:
      containers:
      - name: nginx
        image: nginx:1.21
        resources:
          requests:
            cpu: 100m
            memory: 128Mi
          limits:
            cpu: 200m
            memory: 256Mi
EOF
```

Watch Karpenter provision a node:
```bash
kubectl get nodes -w
kubectl get pods -w
```

### **Test 2: ARM Spot Instance Usage**

Check if ARM-based spot instances are being used:
```bash
kubectl get nodes -l karpenter.sh/capacity-type=spot
kubectl get nodes -l kubernetes.io/arch=arm64
kubectl get nodes -o custom-columns=NAME:.metadata.name,INSTANCE-TYPE:.metadata.labels.node\\.kubernetes\\.io/instance-type,ARCH:.metadata.labels.kubernetes\\.io/arch,CAPACITY-TYPE:.metadata.labels.karpenter\\.sh/capacity-type
```

### **Test 3: External DNS**

Create an ingress to test External DNS:

```bash
cat <<EOF | kubectl apply -f -
apiVersion: networking.k8s.io/v1
kind: Ingress
metadata:
  name: test-ingress
  annotations:
    kubernetes.io/ingress.class: nginx
    external-dns.alpha.kubernetes.io/hostname: test.your-domain.com
spec:
  rules:
  - host: test.your-domain.com
    http:
      paths:
      - path: /
        pathType: Prefix
        backend:
          service:
            name: test-karpenter
            port:
              number: 80
EOF
```

### **Test 4: Cert-Manager**

Check certificate status:
```bash
kubectl get certificates
kubectl get certificaterequests
kubectl get orders
```

### **Test 5: Secrets Store CSI Driver**

Create a test secret:
```bash
kubectl apply -f - <<EOF
apiVersion: v1
kind: Pod
metadata:
  name: test-secrets-store
spec:
  containers:
  - name: test
    image: busybox
    command: ["sleep", "3600"]
    volumeMounts:
    - name: secrets-store
      mountPath: "/mnt/secrets-store"
      readOnly: true
  volumes:
  - name: secrets-store
    csi:
      driver: secrets-store.csi.k8s.io
      readOnly: true
      volumeAttributes:
        secretProviderClass: "aws-secrets"
EOF
```

### **Test 6: ArgoCD**

Access ArgoCD and create a test application:

```bash
# Get ArgoCD admin password
kubectl -n argocd get secret argocd-initial-admin-secret -o jsonpath="{.data.password}" | base64 -d

# Port forward to access ArgoCD
kubectl port-forward svc/argocd-server -n argocd 8080:443
```

Then access `https://localhost:8080` and login with `admin` and the password from above.

### **Test 7: Crossplane**

Check Crossplane providers:
```bash
kubectl get providers
kubectl get providerconfigs
```

### **Test 8: ACK Controllers**

Check ACK controllers:
```bash
kubectl get pods -n ack-system
kubectl api-resources | grep aws
```

## 📊 **Monitoring and Observability**

### **Prometheus Metrics**

Access Prometheus to view metrics:
```bash
kubectl port-forward svc/prometheus-server -n monitoring 9090:80
```

Then access `http://localhost:9090`

### **Grafana Dashboards**

Access Grafana for dashboards:
```bash
kubectl port-forward svc/grafana -n monitoring 3000:80
```

Then access `http://localhost:3000` with `admin/admin123`

### **CloudWatch Integration**

The platform includes CloudWatch integration for:
- Node metrics (CPU, memory, disk)
- Application logs
- Custom metrics
- Alarms and notifications

## 🛡️ **Security Features**

### **Network Security**
- VPC with private/public subnets
- Security groups with least privilege
- Network policies (when enabled)

### **Identity and Access**
- IAM roles for service accounts (IRSA)
- RBAC for Kubernetes
- AWS IAM integration

### **Secrets Management**
- AWS Secrets Manager integration
- SSM Parameter Store integration
- Automatic secret rotation

### **Certificate Management**
- Automatic TLS certificate provisioning
- Let's Encrypt integration
- ACM certificate support

## 🔄 **GitOps Workflow**

### **ArgoCD Applications**

Create applications in ArgoCD to deploy workloads:

```yaml
apiVersion: argoproj.io/v1alpha1
kind: Application
metadata:
  name: my-app
  namespace: argocd
spec:
  project: default
  source:
    repoURL: https://github.com/your-org/your-app
    targetRevision: HEAD
    path: k8s
  destination:
    server: https://kubernetes.default.svc
    namespace: default
  syncPolicy:
    automated:
      prune: true
      selfHeal: true
```

### **Crossplane Resources**

Create infrastructure resources with Crossplane:

```yaml
apiVersion: s3.aws.upbound.io/v1beta1
kind: Bucket
metadata:
  name: my-bucket
spec:
  forProvider:
    region: us-west-2
```

## 🚨 **Troubleshooting**

### **Common Issues**

#### **1. Components Not Starting**
```bash
# Check pod status
kubectl get pods --all-namespaces

# Check pod logs
kubectl logs -n <namespace> <pod-name>

# Check events
kubectl get events --sort-by=.metadata.creationTimestamp
```

#### **2. Karpenter Not Provisioning Nodes**
```bash
# Check Karpenter logs
kubectl logs -n karpenter deployment/karpenter

# Check NodePools
kubectl describe nodepool cost-optimized

# Check IAM permissions
aws sts get-caller-identity
```

#### **3. External DNS Not Working**
```bash
# Check External DNS logs
kubectl logs -n kube-system -l app.kubernetes.io/name=external-dns

# Check Route53 permissions
aws route53 list-hosted-zones
```

#### **4. Cert-Manager Issues**
```bash
# Check certificate status
kubectl get certificates
kubectl describe certificate <cert-name>

# Check cert-manager logs
kubectl logs -n cert-manager deployment/cert-manager
```

### **Debug Commands**

```bash
# Get detailed node information
kubectl describe nodes

# Check all resources
kubectl get all --all-namespaces

# Check ingress status
kubectl get ingress --all-namespaces

# Check services
kubectl get svc --all-namespaces

# Check persistent volumes
kubectl get pv,pvc --all-namespaces
```

## 🔄 **Maintenance**

### **Updating Components**

1. **Update component versions** in `variables.tf`
2. **Run terraform apply**
3. **Verify updates**:
   ```bash
   kubectl get pods --all-namespaces
   ```

### **Scaling NodePools**

```bash
# Update NodePool limits
kubectl patch nodepool cost-optimized --type merge -p '{"spec":{"limits":{"cpu":"2000"}}}'
```

### **Adding New Instance Types**

1. Update `karpenter_instance_types` in `terraform.tfvars`
2. Run `terraform apply`
3. Verify: `kubectl describe nodepool cost-optimized`

## 📚 **Next Steps**

After successful setup, you can:

1. **Deploy Applications**: Use ArgoCD to deploy your applications
2. **Create Infrastructure**: Use Crossplane to provision AWS resources
3. **Monitor Performance**: Use Grafana dashboards and Prometheus metrics
4. **Implement Security**: Add network policies and RBAC rules
5. **Scale Workloads**: Use Karpenter for automatic scaling
6. **Manage Secrets**: Use Secrets Store CSI Driver for secure secret management

## 🆘 **Support**

If you encounter issues:

1. Check the troubleshooting section above
2. Review component logs
3. Check AWS CloudWatch logs
4. Review GitHub Actions logs for deployment issues
5. Check the component documentation:
   - [Karpenter](https://karpenter.sh/)
   - [ArgoCD](https://argo-cd.readthedocs.io/)
   - [Crossplane](https://crossplane.io/)
   - [Prometheus](https://prometheus.io/)
   - [Grafana](https://grafana.com/)

---

**Last Updated**: $(date)  
**Version**: 1.0.0  
**Maintainer**: DevOps Team
