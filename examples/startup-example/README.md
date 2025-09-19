# Startup Configuration Example 🚀

This example is optimized for **startups and small teams** who need:
- Cost-effective infrastructure
- Simple, single-cloud setup
- Fast time-to-market
- Minimal operational overhead

## 🎯 **Configuration Highlights**

### **Cost Optimizations**
- Single AWS region (us-east-1)
- Smaller instance types (t3.micro, t3.small)
- Skip staging environment (dev → prod)
- Use GitHub Container Registry (free for public repos)
- Minimal monitoring stack

### **Simplified Architecture**
- AWS-only (no multi-cloud complexity)
- Basic networking setup
- Essential add-ons only
- Simplified security (production-ready but not enterprise-grade)

## 📋 **Setup Instructions**

### **1. Prerequisites**
- [ ] AWS account with administrative access
- [ ] Domain name registered
- [ ] GitHub organization created
- [ ] Basic CLI tools installed (aws, gh)

### **2. Copy Configuration**
```bash
# Copy this example to your project root
cp -r examples/startup-example/* .

# Customize organization.yaml with your details
vim organization.yaml
```

### **3. Update Key Values**
Edit `organization.yaml` and replace:
- `acme-startup` → your organization name
- `acme-startup.com` → your domain
- `devops@acme-startup.com` → your email
- `123456789012` → your AWS account ID
- `Z1234567890ABC` → your Route53 zone ID

### **4. GitHub Repository Setup**

**Variables to set:**
```bash
gh variable set ORG_NAME --body "acme-startup"
gh variable set ORG_DOMAIN --body "acme-startup.com"
gh variable set ORG_EMAIL --body "devops@acme-startup.com"
gh variable set AWS_ACCOUNT_ID --body "123456789012"
gh variable set ROUTE53_ZONE_ID --body "Z1234567890ABC"
```

**Secrets to set:**
```bash
# Add via GitHub UI (Settings → Secrets and variables → Actions)
AWS_ACCESS_KEY_ID=AKIA...
AWS_SECRET_ACCESS_KEY=...
```

### **5. Deploy Infrastructure**

```bash
# 1. Deploy network
gh workflow run "Network Infrastructure" \
  --field environment=dev \
  --field action=apply \
  --field cloud_provider=aws

# 2. Deploy cluster
gh workflow run "Kubernetes Clusters" \
  --field environment=dev \
  --field action=apply \
  --field cloud_provider=aws

# 3. Deploy add-ons
gh workflow run "Kubernetes Add-ons (Terraform)" \
  --field cluster_name=acme-aws-dev \
  --field environment=dev \
  --field cloud_provider=aws \
  --field action=apply
```

## 💰 **Cost Estimates**

**Monthly AWS costs (approximate):**
- EKS Cluster: $75/month
- Worker nodes (2x t3.small): $30/month
- Load balancer: $20/month
- Route53: $1/month
- **Total: ~$126/month**

**Cost optimization tips:**
- Use Spot instances for development
- Scale down during off-hours
- Use AWS Free Tier where applicable
- Monitor costs with AWS Cost Explorer

## 🔧 **Customization Options**

### **Add Staging Environment**
If you need staging, add to `organization.yaml`:
```yaml
naming:
  environments:
    - "dev"
    - "staging"  # Add this
    - "prod"
```

### **Enable Multi-Region**
For high availability, add secondary region:
```yaml
cloud_accounts:
  aws:
    regions:
      primary: "us-east-1"
      secondary: "us-west-2"  # Add this
```

### **Upgrade Instance Types**
For better performance:
```yaml
defaults:
  vm_sizes:
    aws:
      small: "t3.small"    # Upgrade from t3.micro
      medium: "t3.medium"  # Upgrade from t3.small
      large: "t3.large"    # Upgrade from t3.medium
```

## 🚨 **Production Readiness**

Before going to production:
- [ ] Enable backup strategies
- [ ] Set up monitoring and alerting
- [ ] Configure log aggregation
- [ ] Implement security scanning
- [ ] Set up disaster recovery plan
- [ ] Configure SSL certificates
- [ ] Set up domain and DNS properly

## 📚 **Next Steps**

1. **Deploy development environment** first
2. **Test your applications** in the dev environment
3. **Set up CI/CD pipelines** for your applications
4. **Deploy production environment** when ready
5. **Monitor and optimize** costs and performance

## 🆘 **Support**

- Check the [Troubleshooting Guide](../../docs/TROUBLESHOOTING.md)
- Review [Cloud Account Setup](../../docs/CLOUD_ACCOUNT_SETUP.md)
- Open an issue in the repository for help

---

**Remember**: Start small, iterate fast, and scale as you grow! 🚀
