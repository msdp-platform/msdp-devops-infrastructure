# Error Handling Framework

This document outlines the error handling and validation patterns implemented across all Terraform modules.

## Validation Rules Implemented

### 1. Email Validation
```hcl
validation {
  condition     = can(regex("^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\\.[a-zA-Z]{2,}$", var.email))
  error_message = "Email must be a valid email address format."
}
```

### 2. Hostname Validation
```hcl
validation {
  condition     = can(regex("^[a-zA-Z0-9]([a-zA-Z0-9\\-]{0,61}[a-zA-Z0-9])?(\\.[a-zA-Z0-9]([a-zA-Z0-9\\-]{0,61}[a-zA-Z0-9])?)*$", var.hostname))
  error_message = "Hostname must be a valid DNS hostname format."
}
```

### 3. DNS Label Validation
```hcl
validation {
  condition     = can(regex("^[a-z0-9]([a-z0-9-]{0,61}[a-z0-9])?$", var.txt_owner_id))
  error_message = "TXT owner ID must be a valid DNS label (lowercase alphanumeric and hyphens, max 63 chars)."
}
```

### 4. Timeout Validation
```hcl
validation {
  condition     = var.installation_timeout >= 60 && var.installation_timeout <= 3600
  error_message = "Installation timeout must be between 60 and 3600 seconds (1 minute to 1 hour)."
}
```

### 5. Enum Validation
```hcl
validation {
  condition     = contains(["aws", "azure"], var.cloud_provider)
  error_message = "Cloud provider must be either 'aws' or 'azure'."
}
```

## Error Handling Patterns

### 1. Conditional Resource Creation
```hcl
resource "kubernetes_namespace" "example" {
  count = var.enabled ? 1 : 0
  
  metadata {
    name = var.namespace
  }
}
```

### 2. Dependency Management
```hcl
resource "helm_release" "example" {
  depends_on = [
    kubernetes_namespace.example,
    module.shared_dependencies
  ]
}
```

### 3. Error Recovery
```hcl
resource "helm_release" "example" {
  atomic          = var.atomic_installation
  cleanup_on_fail = true
  timeout         = var.installation_timeout
  wait            = true
  wait_for_jobs   = true
}
```

## Validation Coverage by Module

| Module | Email | Hostname | Timeout | Cloud Provider | Log Level | Custom |
|--------|-------|----------|---------|----------------|-----------|---------|
| cert-manager | ✅ | - | ✅ | ✅ | ✅ | DNS Provider |
| external-dns | - | - | ✅ | ✅ | ✅ | TXT Owner ID |
| nginx-ingress | - | - | ✅ | - | - | Service Type |
| argocd | - | ✅ | ✅ | - | - | - |
| prometheus-stack | - | ✅ (2x) | ✅ | - | - | - |
| keda | - | - | - | - | ✅ | - |
| karpenter | - | - | - | - | ✅ | AMI Family |
| azure-disk-csi-driver | - | - | - | - | - | Storage Class |

## Best Practices

### 1. Input Validation
- Validate all user inputs at the variable level
- Use regex patterns for format validation
- Use `contains()` for enum validation
- Validate ranges for numeric inputs

### 2. Error Messages
- Provide clear, actionable error messages
- Include valid options in enum validation messages
- Specify acceptable ranges for numeric validations

### 3. Resource Dependencies
- Use explicit `depends_on` for critical dependencies
- Implement proper resource ordering
- Handle conditional resource creation

### 4. Recovery Mechanisms
- Enable atomic installations where possible
- Set appropriate timeouts
- Use cleanup on failure
- Implement retry logic where applicable

## Common Validation Patterns

### Cloud Provider Validation
```hcl
validation {
  condition     = contains(["aws", "azure"], var.cloud_provider)
  error_message = "Cloud provider must be either 'aws' or 'azure'."
}
```

### Log Level Validation
```hcl
validation {
  condition     = contains(["debug", "info", "warn", "error"], var.log_level)
  error_message = "Log level must be one of: debug, info, warn, error."
}
```

### Numeric Range Validation
```hcl
validation {
  condition     = var.replica_count >= 1 && var.replica_count <= 10
  error_message = "Replica count must be between 1 and 10."
}
```

## Testing Validation Rules

### Valid Inputs
```bash
# Test with valid inputs
terraform plan -var="email=admin@example.com" -var="hostname=app.example.com"
```

### Invalid Inputs
```bash
# Test with invalid inputs to verify validation
terraform plan -var="email=invalid-email" -var="hostname=invalid..hostname"
```

## Troubleshooting

### Common Validation Errors

1. **Invalid Email Format**
   - Error: Email must be a valid email address format
   - Solution: Use format like `user@domain.com`

2. **Invalid Hostname**
   - Error: Hostname must be a valid DNS hostname format
   - Solution: Use valid DNS names like `app.example.com`

3. **Timeout Out of Range**
   - Error: Installation timeout must be between 60 and 3600 seconds
   - Solution: Use values between 1 minute and 1 hour

4. **Invalid Cloud Provider**
   - Error: Cloud provider must be either 'aws' or 'azure'
   - Solution: Use only supported cloud providers

## Future Improvements

1. Add validation for AWS ARN formats
2. Implement Azure resource ID validation
3. Add Kubernetes resource name validation
4. Implement CIDR block validation for network configurations
5. Add certificate validation for TLS configurations
