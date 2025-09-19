# Documentation Structure

This directory contains all project documentation organized by category:

## 📁 Directory Structure

### `/archive/`
Historical documentation and completed migration notes:
- Change summaries and cleanup records
- Dependency restoration notes
- Naming convention alignment records
- Legacy fix documentation

### `/implementation-notes/`
Technical implementation details and architecture decisions:
- Kubernetes addons architecture and analysis
- Multi-cloud compliance strategies
- Terraform vs Helm analysis
- Azure deployment flows
- AWS/Azure integration patterns

### `/troubleshooting/`
Issue resolution guides and fixes:
- AKS workflow fixes
- Network deployment issues
- GitHub Actions deprecation fixes
- Deployment order problems

### `/ci-cd/`
CI/CD pipeline documentation and guides

### `/preflight/`
Pre-deployment checklists and requirements

## 📋 Key Documents

- `azure-auth-troubleshooting.md` - Azure authentication issues
- `azure-oidc-setup-guide.md` - OIDC configuration guide
- `implementation-guide.md` - General implementation guide
- `terraform-backend-*.md` - Terraform backend strategies

## 🔍 Finding Documentation

Use the following patterns to locate specific documentation:

- **Architecture decisions**: `/implementation-notes/`
- **Deployment issues**: `/troubleshooting/`
- **Historical context**: `/archive/`
- **Setup guides**: Root level `.md` files
- **Pipeline issues**: `/ci-cd/`

## 📝 Contributing

When adding new documentation:
1. Place in appropriate category directory
2. Use descriptive filenames
3. Include date in filename for time-sensitive docs
4. Update this README if adding new categories
