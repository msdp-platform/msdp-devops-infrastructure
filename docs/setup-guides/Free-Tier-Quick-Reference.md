# 🆓 Free Tier Quick Reference Card

Quick reference for free tier limits and costs across AWS, GCP, and Azure.

## 📊 Free Tier Comparison

| Service | AWS | GCP | Azure | Duration |
|---------|-----|-----|-------|----------|
| **Compute** | 750h t2.micro | 1 f1-micro | 750h B1S | 12 months |
| **Database** | 750h db.t2.micro | 1 db-f1-micro | 750h Basic B1ms | 12 months |
| **Cache** | 750h cache.t2.micro | ❌ Not free | ❌ Not free | 12 months |
| **Storage** | 5GB S3 | 5GB Storage | 5GB Blob | Always free |
| **Functions** | 1M requests | 2M requests | 1M requests | Always free |
| **Credits** | $0 | $300 | $200 | 12 months |

## 💰 Cost Breakdown (Development)

### AWS Free Tier (12 months)
```
✅ FREE Services:
- EC2: 750 hours/month t2.micro
- RDS: 750 hours/month db.t2.micro (20GB)
- ElastiCache: 750 hours/month cache.t2.micro
- S3: 5GB storage
- Lambda: 1M requests/month
- API Gateway: 1M calls/month

Monthly Cost: $0
```

### GCP Free Tier (12 months + $300)
```
✅ FREE Services:
- Compute: 1 f1-micro/month
- Cloud SQL: 1 db-f1-micro/month (10GB)
- Storage: 5GB/month
- Functions: 2M requests/month
- Cloud Run: 2M requests/month

❌ NOT FREE:
- Memorystore Redis: ~$30/month

Monthly Cost: $0-30 (covered by $300 credit)
```

### Azure Free Tier (12 months + £100)
```
✅ FREE Services:
- VMs: 750 hours/month B1S
- Database: 750 hours/month Basic B1ms (32GB)
- Storage: 5GB/month
- Functions: 1M requests/month
- App Service: 10 web apps

❌ NOT FREE:
- Cache for Redis: ~$15/month

Monthly Cost: $0-15 (covered by £100 credit)
```

## 🎯 Recommended Strategy

### Phase 1: Development (Months 1-12)
```
Primary: AWS Free Tier
- PostgreSQL: db.t2.micro (20GB) - FREE
- Redis: cache.t2.micro - FREE
- Storage: S3 (5GB) - FREE
- Functions: Lambda (1M requests) - FREE

Monthly Cost: $0
```

### Phase 2: Extended Testing (Months 13-24)
```
Option A: GCP with $300 Credit
- PostgreSQL: db-f1-micro (10GB) - FREE
- Redis: Basic (1GB) - $30/month
- Storage: Cloud Storage (5GB) - FREE

Monthly Cost: $30 (10 months covered by credit)

Option B: Azure with £100 Credit
- PostgreSQL: Basic B1ms (32GB) - FREE
- Redis: Basic C1 (1GB) - $15/month
- Storage: Blob (5GB) - FREE

Monthly Cost: $15 (6 months covered by credit)
```

## 🆓 Always Free Alternatives

### Local Development
```
Minikube + Docker Compose:
- PostgreSQL: Docker container - FREE
- Redis: Docker container - FREE
- Kubernetes: Minikube - FREE
- Total Cost: $0
```

### Open Source Services
```
Database:
- PostgreSQL: Self-hosted - FREE
- Redis: Self-hosted - FREE
- MongoDB: Self-hosted - FREE

Compute:
- Kubernetes: Minikube/Kind - FREE
- Docker: Local containers - FREE

Storage:
- MinIO: S3-compatible - FREE
- Local filesystem - FREE
```

### Free Cloud Services
```
Serverless:
- Vercel: 100GB-hours/month - FREE
- Netlify: 125K requests/month - FREE
- Railway: $5 credit/month - FREE

CI/CD:
- GitHub Actions: 2,000 minutes/month - FREE
- GitLab CI: 400 minutes/month - FREE

Monitoring:
- Grafana Cloud: 10K series - FREE
- Prometheus: Self-hosted - FREE
```

## ⚡ Quick Commands

### Check Free Tier Usage
```bash
# AWS
aws ce get-cost-and-usage --time-period Start=2024-01-01,End=2024-01-31 --granularity MONTHLY --metrics BlendedCost

# GCP
gcloud billing budgets list --billing-account=YOUR_BILLING_ACCOUNT

# Azure
az consumption usage list --start-date 2024-01-01 --end-date 2024-01-31
```

### Set Up Billing Alerts
```bash
# AWS
aws budgets create-budget --account-id YOUR_ACCOUNT_ID --budget '{"BudgetName": "Free-Tier-Monitor", "BudgetLimit": {"Amount": "10", "Unit": "USD"}, "TimeUnit": "MONTHLY", "BudgetType": "COST"}'

# GCP
gcloud billing budgets create --billing-account=YOUR_BILLING_ACCOUNT --display-name="Free-Tier-Monitor" --budget-amount=10USD

# Azure
az consumption budget create --budget-name "Free-Tier-Monitor" --amount 10 --category Cost --time-grain Monthly
```

## 🚨 Cost Alerts Thresholds

| Cloud Provider | Alert Threshold | Action |
|----------------|----------------|--------|
| **AWS** | $10/month | Review usage |
| **GCP** | $20/month | Check free tier |
| **Azure** | $15/month | Monitor spending |

## 📈 Scaling Costs

### Development → Testing
```
AWS: $0 → $26/month
GCP: $0 → $50/month
Azure: $0 → $27/month
```

### Testing → Production
```
AWS: $26 → $200/month
GCP: $50 → $250/month
Azure: $27 → $200/month
```

## 🎯 Best Practices

1. **Start with AWS Free Tier** (most comprehensive)
2. **Use your Azure £100 credit** for extended testing
3. **Set up billing alerts** to avoid surprise bills
4. **Implement resource scheduling** for cost optimization
5. **Monitor usage regularly** to stay within limits
6. **Plan multi-cloud strategy** for production

## 📞 Support

- **AWS Support**: Basic support included in free tier
- **GCP Support**: Community support only
- **Azure Support**: Basic support included in free tier

---

**💡 Pro Tip**: You can develop and test the entire Multi-Service Delivery Platform for **$0-30/month** using free tiers and credits! 🎉
