# 🆓 AWS Free Tier Setup Guide

## Quick Setup for Your Multi-Service Delivery Platform

### **Step 1: Configure AWS CLI**

Since you're already logged into AWS in your browser, follow these steps:

#### **1.1 Get Your Access Keys**
1. Go to **AWS Console** → **IAM** → **Users** → **Your Username**
2. Click **Security credentials** tab
3. Click **Create access key**
4. Choose **Command Line Interface (CLI)**
5. **Copy the Access Key ID and Secret Access Key**

#### **1.2 Configure AWS CLI**
```bash
aws configure
```

Enter the following when prompted:
- **AWS Access Key ID**: [Your Access Key ID]
- **AWS Secret Access Key**: [Your Secret Access Key]
- **Default region name**: `us-east-1`
- **Default output format**: `json`

### **Step 2: Check Free Tier Eligibility**

Run the Free Tier checker script:
```bash
./scripts/check-aws-free-tier.sh
```

### **Step 3: Verify Your Free Tier Status**

#### **3.1 Check Account Information**
```bash
aws sts get-caller-identity
```

#### **3.2 Check Free Tier Usage**
```bash
aws ce get-cost-and-usage \
  --time-period Start=2024-01-01,End=2024-01-31 \
  --granularity MONTHLY \
  --metrics BlendedCost
```

### **Step 4: Set Up Free Tier Services**

#### **4.1 Create S3 Bucket (Free Tier)**
```bash
aws s3 mb s3://your-delivery-platform-bucket
```

#### **4.2 Create RDS PostgreSQL Instance (Free Tier)**
```bash
aws rds create-db-instance \
  --db-instance-identifier delivery-platform-db \
  --db-instance-class db.t2.micro \
  --engine postgres \
  --master-username admin \
  --master-user-password YourPassword123 \
  --allocated-storage 20 \
  --storage-type gp2
```

#### **4.3 Create ElastiCache Redis (Free Tier)**
```bash
aws elasticache create-cache-cluster \
  --cache-cluster-id delivery-platform-redis \
  --cache-node-type cache.t2.micro \
  --engine redis \
  --num-cache-nodes 1
```

### **Step 5: Set Up Crossplane AWS Provider**

#### **5.1 Install AWS Provider**
```bash
kubectl crossplane install provider xpkg.upbound.io/crossplane-contrib/provider-aws:v0.44.0
```

#### **5.2 Create AWS Provider Config**
```bash
cat <<EOF | kubectl apply -f -
apiVersion: aws.crossplane.io/v1beta1
kind: ProviderConfig
metadata:
  name: aws-provider-config
spec:
  credentials:
    source: Secret
    secretRef:
      namespace: crossplane-system
      name: aws-creds
      key: credentials
EOF
```

#### **5.3 Create AWS Credentials Secret**
```bash
kubectl create secret generic aws-creds \
  --from-literal=credentials="[default]
aws_access_key_id = YOUR_ACCESS_KEY
aws_secret_access_key = YOUR_SECRET_KEY
region = us-east-1" \
  -n crossplane-system
```

### **Step 6: Deploy Your First Service**

#### **6.1 Create Database Claim**
```bash
cat <<EOF | kubectl apply -f -
apiVersion: database.example.org/v1alpha1
kind: DatabaseClaim
metadata:
  name: delivery-platform-db
spec:
  parameters:
    engine: postgres
    instanceClass: db.t2.micro
    allocatedStorage: 20
    region: us-east-1
  writeConnectionSecretsToRef:
    name: delivery-platform-db-secret
    namespace: default
EOF
```

#### **6.2 Create Redis Claim**
```bash
cat <<EOF | kubectl apply -f -
apiVersion: cache.example.org/v1alpha1
kind: RedisClaim
metadata:
  name: delivery-platform-redis
spec:
  parameters:
    nodeType: cache.t2.micro
    numCacheNodes: 1
    region: us-east-1
  writeConnectionSecretsToRef:
    name: delivery-platform-redis-secret
    namespace: default
EOF
```

### **Step 7: Verify Deployment**

#### **7.1 Check Crossplane Resources**
```bash
kubectl get providers
kubectl get compositions
kubectl get claims
```

#### **7.2 Check AWS Resources**
```bash
aws rds describe-db-instances --query 'DBInstances[*].[DBInstanceIdentifier,DBInstanceClass,DBInstanceStatus]' --output table
aws elasticache describe-cache-clusters --query 'CacheClusters[*].[CacheClusterId,CacheNodeType,CacheClusterStatus]' --output table
```

### **Step 8: Set Up Cost Monitoring**

#### **8.1 Create Billing Alert**
```bash
aws budgets create-budget \
  --account-id $(aws sts get-caller-identity --query 'Account' --output text) \
  --budget '{
    "BudgetName": "Free-Tier-Monitor",
    "BudgetLimit": {"Amount": "10", "Unit": "USD"},
    "TimeUnit": "MONTHLY",
    "BudgetType": "COST"
  }'
```

#### **8.2 Set Up Cost Alerts**
```bash
aws budgets create-notification \
  --account-id $(aws sts get-caller-identity --query 'Account' --output text) \
  --budget-name "Free-Tier-Monitor" \
  --notification '{
    "NotificationType": "ACTUAL",
    "ComparisonOperator": "GREATER_THAN",
    "Threshold": 5,
    "ThresholdType": "ABSOLUTE_VALUE"
  }' \
  --subscribers '[
    {"SubscriptionType": "EMAIL", "Address": "your-email@example.com"}
  ]'
```

## 🎯 **Free Tier Services for Your Platform**

### **Database Services**
- **RDS PostgreSQL**: db.t2.micro, 20GB storage - **FREE**
- **ElastiCache Redis**: cache.t2.micro - **FREE**
- **DynamoDB**: 25GB storage, 25 read/write capacity units - **FREE**

### **Compute Services**
- **Lambda**: 1M requests/month, 400,000 GB-seconds - **FREE**
- **API Gateway**: 1M API calls/month - **FREE**
- **EC2**: 750 hours/month t2.micro - **FREE**

### **Storage Services**
- **S3**: 5GB storage, 20,000 GET requests, 2,000 PUT requests - **FREE**
- **EBS**: 30GB storage - **FREE**

### **Monitoring Services**
- **CloudWatch**: 10 custom metrics, 5GB log ingestion - **FREE**

## 💰 **Cost Breakdown**

| Service | Free Tier Limit | Monthly Cost |
|---------|----------------|--------------|
| **RDS PostgreSQL** | 750 hours, 20GB | $0 |
| **ElastiCache Redis** | 750 hours | $0 |
| **DynamoDB** | 25GB, 25 RCU/WCU | $0 |
| **Lambda** | 1M requests | $0 |
| **API Gateway** | 1M calls | $0 |
| **S3** | 5GB storage | $0 |
| **CloudWatch** | 10 metrics, 5GB logs | $0 |
| **Total** | | **$0/month** |

## 🚀 **Next Steps**

1. **Configure AWS CLI** with your credentials
2. **Run the Free Tier checker** script
3. **Set up Crossplane AWS provider**
4. **Deploy your first database** using Crossplane
5. **Set up cost monitoring** to stay within free tier
6. **Start developing** your multi-service platform!

## 🎉 **Benefits**

- **FREE development** for 12 months
- **Production-ready** services
- **Automatic scaling** capabilities
- **Enterprise-grade** reliability
- **No upfront costs** or commitments

**You can develop your entire multi-service delivery platform for FREE using AWS Free Tier!** 🚀
