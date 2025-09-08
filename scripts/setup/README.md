# 🚀 MSDP Platform Setup Scripts

## 🎯 **Overview**

This directory contains scripts for setting up the entire MSDP platform ecosystem, including repository initialization, team management, and branch configuration.

## 📁 **Setup Scripts**

### **`initialize-repositories.sh`**
- **Purpose**: Initialize all MSDP repositories with initial commits
- **Usage**: `./scripts/setup/initialize-repositories.sh`
- **Function**: Creates initial README files and commits for all platform repositories

### **`setup-all-repositories.sh`**
- **Purpose**: Add all repositories to platform-engineering team and set up branch protection
- **Usage**: `./scripts/setup/setup-all-repositories.sh`
- **Function**: Configures team access and branch protection rules

### **`setup-multi-environment-branches.sh`**
- **Purpose**: Set up multi-environment branches (dev, test, prod) for all repositories
- **Usage**: `./scripts/setup/setup-multi-environment-branches.sh`
- **Function**: Creates and configures environment-specific branches

## 🏗️ **MSDP Platform Repositories**

The setup scripts manage the following repositories:

### **Core Platform**
- `msdp-platform-core` - Core platform services
- `msdp-security` - Security services and policies
- `msdp-monitoring` - Monitoring and observability

### **Business Units**
- `msdp-food-delivery` - Food delivery services
- `msdp-grocery-delivery` - Grocery delivery services
- `msdp-cleaning-services` - Cleaning services
- `msdp-repair-services` - Repair services

### **Applications**
- `msdp-customer-app` - Customer-facing application
- `msdp-provider-app` - Provider-facing application
- `msdp-admin-dashboard` - Administrative dashboard

### **Services & Components**
- `msdp-analytics-services` - Analytics and reporting
- `msdp-ui-components` - Shared UI components
- `msdp-api-sdk` - API SDK and libraries
- `msdp-testing-utils` - Testing utilities
- `msdp-shared-libs` - Shared libraries
- `msdp-documentation` - Platform documentation

## 🚀 **Quick Start**

### **1. Initialize All Repositories**
```bash
./scripts/setup/initialize-repositories.sh
```

### **2. Set Up Team Access**
```bash
./scripts/setup/setup-all-repositories.sh
```

### **3. Configure Environment Branches**
```bash
./scripts/setup/setup-multi-environment-branches.sh
```

## 🔧 **Prerequisites**

- **GitHub CLI**: `gh` command-line tool installed and authenticated
- **Git**: Git command-line tool
- **Access**: Admin access to `msdp-platform` organization
- **Team ID**: Platform-engineering team ID configured

## 📊 **Script Features**

### **Repository Initialization**
- Creates initial README files
- Sets up basic repository structure
- Configures initial commits
- Sets up branch protection

### **Team Management**
- Adds repositories to platform-engineering team
- Configures team permissions
- Sets up branch protection rules
- Manages repository access

### **Branch Configuration**
- Creates dev, test, prod branches
- Sets up branch protection rules
- Configures merge policies
- Sets up environment-specific workflows

## 🎯 **Usage Notes**

- **One-time setup**: These scripts are typically run once during platform initialization
- **Admin access required**: Requires admin access to the GitHub organization
- **Team configuration**: Ensure team IDs are correctly configured
- **Repository list**: Update repository list if new repositories are added

## 🔒 **Security Considerations**

- **Access control**: Scripts configure team-based access control
- **Branch protection**: Enforces branch protection rules
- **Permission management**: Manages repository permissions
- **Audit trail**: All changes are tracked in Git history

---

**These scripts provide a complete setup solution for the MSDP platform ecosystem.** 🚀
