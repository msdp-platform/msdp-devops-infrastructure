# 🏢 GitHub Organization Setup Guide

## 📋 **Overview**

This guide outlines the setup of a new GitHub organization for the Multi-Service Delivery Platform (MSDP) repositories, providing centralized management and collaboration for the multi-repository architecture.

---

## 🎯 **Organization Strategy**

### **Organization Name**
- **Primary**: `msdp-platform` (recommended)
- **Alternative**: `msdp-delivery-platform`
- **Alternative**: `aztech-msdp`

### **Organization Structure**
```
msdp-platform/
├── msdp-devops-infrastructure     # DevOps infrastructure (this repo)
├── msdp-platform-core            # Shared platform services
├── msdp-food-delivery            # Food delivery services
├── msdp-grocery-delivery         # Grocery delivery services
├── msdp-cleaning-services        # Cleaning services
├── msdp-repair-services          # Repair services
├── msdp-customer-app             # Customer application
├── msdp-provider-app             # Provider application
├── msdp-admin-dashboard          # Admin dashboard
├── msdp-ui-components            # Shared UI components
├── msdp-api-sdk                  # API SDK
├── msdp-testing-utils            # Testing utilities
├── msdp-shared-libs              # Shared libraries
├── msdp-analytics-services       # Analytics services
└── msdp-documentation            # Shared documentation
```

---

## 🚀 **Setup Steps**

### **Step 1: Create GitHub Organization**

1. **Go to GitHub Organizations**
   - Visit: https://github.com/organizations/new
   - Sign in with your GitHub account

2. **Organization Details**
   ```
   Organization account name: msdp-platform
   Contact email: santanubiswas2k@gmail.com
   Organization type: Free (for now, can upgrade later)
   ```

3. **Organization Settings**
   - **Visibility**: Public (for open source components)
   - **Repository creation**: Allow members to create repositories
   - **Base permissions**: Read (for security)

### **Step 2: Configure Organization Settings**

#### **General Settings**
- **Profile**: Add organization description and website
- **Email**: Configure organization email settings
- **Location**: Set organization location
- **Company**: Add company information

#### **Member Privileges**
- **Base permissions**: Read
- **Repository creation**: Allow members
- **Repository forking**: Allow forking
- **Issue creation**: Allow all members

#### **Security Settings**
- **Two-factor authentication**: Require for all members
- **SSH certificate authorities**: Configure if needed
- **Personal access tokens**: Configure token policies

### **Step 3: Set Up Teams**

#### **Platform Engineering Team**
```
Team: platform-engineering
Description: Platform infrastructure and DevOps
Members: [Your GitHub username, My GitHub username]
Repositories: msdp-devops-infrastructure, msdp-platform-core
Permissions: Admin
```

#### **Food Delivery Team**
```
Team: food-delivery
Description: Food delivery services and applications
Members: [Your GitHub username, My GitHub username]
Repositories: msdp-food-delivery, msdp-customer-app
Permissions: Write
```

#### **Shared Services Team**
```
Team: shared-services
Description: Shared libraries and components
Members: [Your GitHub username, My GitHub username]
Repositories: msdp-ui-components, msdp-api-sdk, msdp-shared-libs
Permissions: Write
```

### **Step 4: Repository Migration**

#### **Migrate Existing Repository**
1. **Create new repository in organization**
   ```
   Repository name: msdp-devops-infrastructure
   Description: MSDP DevOps infrastructure and CI/CD
   Visibility: Private (initially)
   ```

2. **Push existing code**
   ```bash
   # Add new remote
   git remote add origin https://github.com/msdp-platform/msdp-devops-infrastructure.git
   
   # Push to new repository
   git push -u origin main
   ```

3. **Update repository settings**
   - Enable GitHub Actions
   - Configure branch protection rules
   - Set up required status checks
   - Configure repository secrets

### **Step 5: Configure Repository Secrets**

#### **Organization Secrets**
```bash
# Azure Configuration
AZURE_CLIENT_ID
AZURE_CLIENT_SECRET
AZURE_TENANT_ID
AZURE_SUBSCRIPTION_ID
AZURE_RESOURCE_GROUP
AKS_CLUSTER_NAME

# Backstage Configuration
SESSION_SECRET
GITHUB_INTEGRATION
AZURE_INTEGRATION
ARGOCD_INTEGRATION
ARGOCD_PASSWORD

# Payment Providers
STRIPE_TOKEN
RAZORPAY_TOKEN
PAYTM_TOKEN

# Government APIs
HMRC_TOKEN
FSSAI_TOKEN
GST_TOKEN
```

#### **Repository Secrets**
- **DOCKER_HUB_TOKEN**: For container registry access
- **NPM_TOKEN**: For npm package publishing
- **SONAR_TOKEN**: For code quality analysis

### **Step 6: Set Up Branch Protection**

#### **Main Branch Protection**
- **Require pull request reviews**: 1 reviewer
- **Dismiss stale reviews**: Yes
- **Require status checks**: Yes
- **Require branches to be up to date**: Yes
- **Restrict pushes**: Yes
- **Allow force pushes**: No
- **Allow deletions**: No

#### **Required Status Checks**
- **GitHub Actions**: All workflows must pass
- **Code quality**: SonarQube analysis
- **Security**: Security scanning
- **Tests**: All tests must pass

---

## 🔧 **Organization Configuration**

### **Webhooks Configuration**

#### **ArgoCD Webhook**
```
Payload URL: https://argocd.dev.aztech-msdp.com/api/webhook
Content type: application/json
Secret: [ArgoCD webhook secret]
Events: Push, Pull request
```

#### **Slack Integration**
```
Payload URL: [Slack webhook URL]
Content type: application/json
Events: Push, Pull request, Issues, Releases
```

### **GitHub Apps**

#### **ArgoCD GitHub App**
- **Installation**: Install ArgoCD GitHub App
- **Permissions**: Repository access
- **Events**: Push, Pull request

#### **Dependabot**
- **Enable**: Enable Dependabot for all repositories
- **Configuration**: Set up dependency updates
- **Security**: Enable security updates

---

## 📊 **Repository Management**

### **Repository Templates**

#### **Service Repository Template**
```yaml
# .github/ISSUE_TEMPLATE/
├── bug_report.md
├── feature_request.md
└── config.yml

# .github/PULL_REQUEST_TEMPLATE.md
# .github/workflows/
├── ci.yml
├── cd.yml
└── security.yml

# .github/
├── CODEOWNERS
├── CONTRIBUTING.md
└── SECURITY.md
```

#### **Infrastructure Repository Template**
```yaml
# .github/workflows/
├── infrastructure-validation.yml
├── security-scan.yml
└── cost-optimization.yml

# .github/
├── CODEOWNERS
├── CONTRIBUTING.md
└── SECURITY.md
```

### **Repository Naming Convention**

#### **Naming Pattern**
```
msdp-{service-type}-{service-name}

Examples:
- msdp-service-food-delivery
- msdp-app-customer
- msdp-lib-ui-components
- msdp-infra-devops
```

#### **Repository Categories**
- **Service**: `msdp-service-*`
- **Application**: `msdp-app-*`
- **Library**: `msdp-lib-*`
- **Infrastructure**: `msdp-infra-*`
- **Documentation**: `msdp-docs-*`

---

## 🔒 **Security Configuration**

### **Organization Security**

#### **Two-Factor Authentication**
- **Require**: All members must enable 2FA
- **Enforcement**: Automatic enforcement
- **Grace period**: 7 days

#### **SSH Certificate Authorities**
- **Configure**: SSH certificate authorities for secure access
- **Validity**: 24 hours
- **Principals**: Organization members

#### **Personal Access Tokens**
- **Expiration**: 90 days
- **Scopes**: Minimal required scopes
- **Audit**: Regular token audit

### **Repository Security**

#### **Code Scanning**
- **GitHub CodeQL**: Enable for all repositories
- **Dependabot**: Enable security updates
- **Secret scanning**: Enable secret detection

#### **Branch Protection**
- **Main branch**: Require PR reviews
- **Status checks**: Require all checks to pass
- **Force push**: Disable force push
- **Deletion**: Disable branch deletion

---

## 📈 **Monitoring and Analytics**

### **Organization Insights**
- **Repository activity**: Monitor repository activity
- **Team productivity**: Track team productivity
- **Code quality**: Monitor code quality metrics
- **Security**: Track security issues

### **Repository Metrics**
- **Commits**: Track commit frequency
- **Pull requests**: Monitor PR activity
- **Issues**: Track issue resolution
- **Releases**: Monitor release frequency

---

## 🚀 **Next Steps**

### **Immediate Actions**
1. **Create GitHub organization**
2. **Set up organization settings**
3. **Create initial teams**
4. **Migrate existing repository**
5. **Configure repository secrets**
6. **Set up branch protection**

### **Future Actions**
1. **Create additional repositories**
2. **Set up CI/CD pipelines**
3. **Configure monitoring**
4. **Set up documentation**
5. **Onboard team members**

---

## 📚 **Additional Resources**

- [GitHub Organizations Documentation](https://docs.github.com/en/organizations)
- [Repository Management](https://docs.github.com/en/repositories)
- [Team Management](https://docs.github.com/en/organizations/organizing-members-into-teams)
- [Security Best Practices](https://docs.github.com/en/code-security)

---

**Setup Guide Version**: 1.0.0  
**Last Updated**: $(date)  
**Target Completion**: Week 1 of implementation
