# AWS Route 53 + Azure Hybrid Setup

## 🌍 **Hybrid Architecture: Route 53 DNS + Azure Infrastructure**

### **✅ What You Can Do**
- **Register domain** in AWS Route 53
- **Host DNS** in AWS Route 53 (Public Hosted Zone)
- **Run infrastructure** in Azure (AKS, LoadBalancer, etc.)
- **Point DNS records** to Azure LoadBalancer IP

## 💰 **Cost Comparison**

### **Option 1: AWS Route 53 + Azure (Hybrid)**
| Service | Provider | Cost | Notes |
|---------|----------|------|-------|
| **Domain Registration** | AWS Route 53 | $12-15/year | Direct registration |
| **DNS Hosting** | AWS Route 53 | $0.50/month | Public Hosted Zone |
| **DNS Queries** | AWS Route 53 | Free (1B queries) | First 1B free |
| **Infrastructure** | Azure | Current cost | AKS, LoadBalancer, etc. |
| **Total DNS Cost** | **~$18-21/year** | | |

### **Option 2: Azure DNS + External Registration**
| Service | Provider | Cost | Notes |
|---------|----------|------|-------|
| **Domain Registration** | External (GoDaddy) | $12-15/year | External registrar |
| **DNS Hosting** | Azure DNS | $0.50/month | Azure DNS Zone |
| **DNS Queries** | Azure DNS | Free (1M queries) | First 1M free |
| **Infrastructure** | Azure | Current cost | AKS, LoadBalancer, etc. |
| **Total DNS Cost** | **~$18-21/year** | | |

### **Option 3: All Azure (Current Setup)**
| Service | Provider | Cost | Notes |
|---------|----------|------|-------|
| **Domain Registration** | External (GoDaddy) | $12-15/year | External registrar |
| **DNS Hosting** | Azure DNS | $0.50/month | Azure DNS Zone |
| **DNS Queries** | Azure DNS | Free (1M queries) | First 1M free |
| **Infrastructure** | Azure | Current cost | AKS, LoadBalancer, etc. |
| **Total DNS Cost** | **~$18-21/year** | | |

## 🎯 **Cost Analysis: Almost Identical!**

| Option | Total DNS Cost | Benefits | Drawbacks |
|--------|----------------|----------|-----------|
| **Route 53 + Azure** | ~$18-21/year | ✅ Direct registration, ✅ 1B free queries | ❌ Two cloud providers |
| **Azure DNS + External** | ~$18-21/year | ✅ Single cloud provider | ❌ External registration |
| **All Azure** | ~$18-21/year | ✅ Single cloud provider | ❌ Quota limits |

## 🚀 **AWS Route 53 + Azure Setup**

### **Step 1: Register Domain in Route 53**
```bash
# Register domain in Route 53
aws route53domains register-domain \
  --domain-name aztech-msdp.com \
  --duration-in-years 1 \
  --admin-contact FirstName=Santanu,LastName=Biswas,ContactType=PERSON,OrganizationName=Aztech,AddressLine1=123 Main St,City=London,State=England,CountryCode=GB,ZipCode=SW1A 1AA,PhoneNumber=+44.2071234567,Email=santanubiswas2k@gmail.com \
  --registrant-contact FirstName=Santanu,LastName=Biswas,ContactType=PERSON,OrganizationName=Aztech,AddressLine1=123 Main St,City=London,State=England,CountryCode=GB,ZipCode=SW1A 1AA,PhoneNumber=+44.2071234567,Email=santanubiswas2k@gmail.com \
  --tech-contact FirstName=Santanu,LastName=Biswas,ContactType=PERSON,OrganizationName=Aztech,AddressLine1=123 Main St,City=London,State=England,CountryCode=GB,ZipCode=SW1A 1AA,PhoneNumber=+44.2071234567,Email=santanubiswas2k@gmail.com
```

### **Step 2: Create Route 53 Hosted Zone**
```bash
# Create public hosted zone
aws route53 create-hosted-zone \
  --name aztech-msdp.com \
  --caller-reference $(date +%s)
```

### **Step 3: Get Azure LoadBalancer IP**
```bash
# Get current Azure LoadBalancer IP
PUBLIC_IP=$(kubectl get svc -n ingress-nginx ingress-nginx-controller -o jsonpath='{.status.loadBalancer.ingress[0].ip}')
echo "Azure LoadBalancer IP: $PUBLIC_IP"
```

### **Step 4: Create DNS Records in Route 53**
```bash
# Create A records pointing to Azure LoadBalancer
aws route53 change-resource-record-sets \
  --hosted-zone-id Z123456789 \
  --change-batch '{
    "Changes": [
      {
        "Action": "CREATE",
        "ResourceRecordSet": {
          "Name": "dev.aztech-msdp.com",
          "Type": "A",
          "TTL": 300,
          "ResourceRecords": [
            {
              "Value": "'$PUBLIC_IP'"
            }
          ]
        }
      },
      {
        "Action": "CREATE",
        "ResourceRecordSet": {
          "Name": "argocd.dev.aztech-msdp.com",
          "Type": "A",
          "TTL": 300,
          "ResourceRecords": [
            {
              "Value": "'$PUBLIC_IP'"
            }
          ]
        }
      },
      {
        "Action": "CREATE",
        "ResourceRecordSet": {
          "Name": "app.dev.aztech-msdp.com",
          "Type": "A",
          "TTL": 300,
          "ResourceRecords": [
            {
              "Value": "'$PUBLIC_IP'"
            }
          ]
        }
      }
    ]
  }'
```

## 🔧 **Alternative: Use Route 53 for DNS Only**

### **If you already have the domain registered elsewhere:**
```bash
# Create Route 53 hosted zone
aws route53 create-hosted-zone \
  --name aztech-msdp.com \
  --caller-reference $(date +%s)

# Get name servers
aws route53 get-hosted-zone --id Z123456789 --query "DelegationSet.NameServers"

# Update name servers at your current registrar
# Point to Route 53 name servers
```

## 📊 **Detailed Cost Breakdown**

### **AWS Route 53 Costs**
- **Domain Registration**: $12-15/year
- **Public Hosted Zone**: $0.50/month = $6/year
- **DNS Queries**: First 1 billion free, then $0.40 per 1M queries
- **Health Checks**: $0.50/month per health check (optional)

### **Azure Infrastructure Costs (Unchanged)**
- **AKS Cluster**: Current cost
- **LoadBalancer**: Current cost
- **Storage**: Current cost
- **Networking**: Current cost

### **Total Additional Cost: ~$6/year**
The only additional cost is the Route 53 hosted zone ($6/year) since you're already paying for domain registration.

## 🎯 **Recommendation**

### **Best Option: Route 53 + Azure Hybrid**
**Why this is the best approach:**

1. **✅ Direct Domain Registration** - No external registrars
2. **✅ 1 Billion Free Queries** - Much higher than Azure's 1M
3. **✅ No Quota Issues** - Route 53 has no VM quotas
4. **✅ Professional Setup** - Industry standard
5. **✅ Cost Effective** - Only $6/year additional cost
6. **✅ Easy Management** - All DNS in one place

### **Setup Steps:**
1. **Register domain** in Route 53 (~$12-15/year)
2. **Create hosted zone** in Route 53 ($6/year)
3. **Point DNS records** to Azure LoadBalancer IP
4. **Keep all infrastructure** in Azure

### **Total Cost: ~$18-21/year**
- Domain registration: $12-15/year
- Route 53 hosted zone: $6/year
- **Same cost as other options, but better features!**

## 🚀 **Quick Start**

```bash
# 1. Register domain in Route 53 (through AWS Console)
# 2. Create hosted zone
aws route53 create-hosted-zone --name aztech-msdp.com --caller-reference $(date +%s)

# 3. Get Azure IP
PUBLIC_IP=$(kubectl get svc -n ingress-nginx ingress-nginx-controller -o jsonpath='{.status.loadBalancer.ingress[0].ip}')

# 4. Create DNS records pointing to Azure
# (Use AWS Console or CLI to create A records)
```

---

**🎯 Bottom Line: Route 53 + Azure hybrid gives you the best of both worlds for the same cost (~$18-21/year) with better features and no quota issues!**
