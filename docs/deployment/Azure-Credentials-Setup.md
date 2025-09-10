# 🔐 Azure Credentials Setup for GitHub Actions

## 🎯 **Current Issue**

The GitHub Actions workflow is running but failing with:
```
Error: Login failed with Error: Using auth-type: SERVICE_PRINCIPAL. 
Not all values are present. Ensure 'client-id' and 'tenant-id' are supplied.
```

This means the `AZURE_CREDENTIALS` secret is not properly configured in GitHub.

## 🚀 **Solution: Configure Azure Service Principal**

### **Step 1: Create Azure Service Principal**

Run this command to create a service principal with the necessary permissions:

```bash
# Create service principal for GitHub Actions
az ad sp create-for-rbac \
  --name "msdp-platform-github-actions" \
  --role contributor \
  --scopes /subscriptions/$(az account show --query id -o tsv) \
  --sdk-auth
```

**Expected Output:**
```json
{
  "clientId": "xxxxxxxx-xxxx-xxxx-xxxx-xxxxxxxxxxxx",
  "clientSecret": "xxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx",
  "subscriptionId": "xxxxxxxx-xxxx-xxxx-xxxx-xxxxxxxxxxxx",
  "tenantId": "xxxxxxxx-xxxx-xxxx-xxxx-xxxxxxxxxxxx",
  "activeDirectoryEndpointUrl": "https://login.microsoftonline.com",
  "resourceManagerEndpointUrl": "https://management.azure.com/",
  "activeDirectoryGraphResourceId": "https://graph.windows.net/",
  "sqlManagementEndpointUrl": "https://management.core.windows.net:8443/",
  "galleryEndpointUrl": "https://gallery.azure.com/",
  "managementEndpointUrl": "https://management.core.windows.net/"
}
```

### **Step 2: Configure GitHub Secrets**

1. **Go to your GitHub repository**
2. **Navigate to**: Settings → Secrets and variables → Actions
3. **Click**: "New repository secret"
4. **Name**: `AZURE_CREDENTIALS`
5. **Value**: Copy the entire JSON output from Step 1
6. **Click**: "Add secret"

### **Step 3: Verify Service Principal Permissions**

```bash
# Check service principal permissions
az role assignment list \
  --assignee "msdp-platform-github-actions" \
  --all

# Verify AKS access
az aks list --resource-group msdp-dev-rg
```

## 🔧 **Alternative: Manual Service Principal Creation**

If the above command doesn't work, create the service principal manually:

### **Step 1: Create Service Principal**
```bash
# Create service principal
az ad sp create-for-rbac \
  --name "msdp-platform-github-actions" \
  --role contributor \
  --scopes /subscriptions/$(az account show --query id -o tsv)
```

### **Step 2: Get Tenant ID**
```bash
# Get tenant ID
az account show --query tenantId -o tsv
```

### **Step 3: Create JSON Manually**
Create the `AZURE_CREDENTIALS` secret with this format:
```json
{
  "clientId": "your-client-id-from-step-1",
  "clientSecret": "your-client-secret-from-step-1",
  "subscriptionId": "your-subscription-id",
  "tenantId": "your-tenant-id-from-step-2"
}
```

## 🧪 **Test Azure Credentials**

### **Test Locally**
```bash
# Test Azure login
az login --service-principal \
  --username "your-client-id" \
  --password "your-client-secret" \
  --tenant "your-tenant-id"

# Test AKS access
az aks get-credentials --resource-group msdp-dev-rg --name msdp-dev-aks
kubectl get nodes
```

### **Test in GitHub Actions**
1. **Go to**: GitHub Actions → "Deploy Platform Components"
2. **Click**: "Run workflow"
3. **Select**: Environment: `dev`, Component: `all`, Dry Run: `true`
4. **Click**: "Run workflow"

## 🚨 **Troubleshooting**

### **Issue: Service Principal Creation Fails**
```bash
# Check if you have permissions
az account show

# Check if you're logged in
az login
```

### **Issue: AKS Access Denied**
```bash
# Grant additional permissions to service principal
az role assignment create \
  --assignee "msdp-platform-github-actions" \
  --role "Azure Kubernetes Service Cluster User Role" \
  --scope "/subscriptions/$(az account show --query id -o tsv)/resourceGroups/msdp-dev-rg/providers/Microsoft.ContainerService/managedClusters/msdp-dev-aks"
```

### **Issue: Resource Group Not Found**
```bash
# Check if resource group exists
az group list --query "[?name=='msdp-dev-rg']"

# Create resource group if it doesn't exist
az group create --name msdp-dev-rg --location eastus
```

## 📋 **Required GitHub Secrets**

Make sure you have these secrets configured:

1. **`AZURE_CREDENTIALS`** - Azure service principal credentials
2. **`AWS_ACCESS_KEY_ID`** - AWS access key for Route53
3. **`AWS_SECRET_ACCESS_KEY`** - AWS secret key for Route53

## 🎯 **Next Steps After Configuration**

1. **Configure Azure credentials** using the steps above
2. **Test the workflow** with dry run
3. **Run actual deployment** if dry run succeeds
4. **Verify platform components** are deployed

---

**Follow these steps to configure Azure credentials and resolve the GitHub Actions authentication issue!** 🔐
