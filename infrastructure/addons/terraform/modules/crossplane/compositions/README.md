# MSDP Crossplane Compositions

This directory contains Crossplane compositions specific to the MSDP platform.

## Available Compositions

### Database Compositions
- `aurora-serverless.yaml` - AWS Aurora PostgreSQL Serverless v2
- `azure-postgresql.yaml` - Azure Database for PostgreSQL Flexible Server

### Cache Compositions  
- `redis-cache.yaml` - Redis cache for session management and caching

### Storage Compositions
- `storage-bucket.yaml` - Object storage for file uploads and assets

## Usage

These compositions are automatically deployed when Crossplane is enabled in the addon configuration. They create composite resource definitions (XRDs) that can be used by MSDP services to provision infrastructure declaratively.

### Example Usage

```yaml
apiVersion: msdp.platform/v1alpha1
kind: XAuroraServerless
metadata:
  name: location-service-db
  namespace: msdp-location-service
spec:
  parameters:
    serviceName: location-service
    environment: dev
    minCapacity: 0.5
    maxCapacity: 2
    backupRetentionPeriod: 7
```

## Integration with ArgoCD

These compositions integrate with ArgoCD applications for GitOps-based infrastructure management. Services can declare their infrastructure requirements in their repository, and ArgoCD will ensure the infrastructure is provisioned via Crossplane.

## Multi-Namespace Strategy

Each MSDP service operates in its own namespace:
- `msdp-location-service` - Location and geographic services
- `msdp-merchant-service` - VendaBuddy marketplace services  
- `msdp-user-service` - User authentication services
- `msdp-order-service` - Order processing services
- `msdp-payment-service` - Payment processing (PCI compliant)
- `msdp-frontend-apps` - All frontend applications

The shared Crossplane instance in `crossplane-system` manages infrastructure for all services while maintaining isolation through namespaces.
