# MSDP Development Namespace

This directory contains Kubernetes manifests and scripts to deploy your MSDP services to a dedicated development namespace in your AKS cluster for individual developer work.

## 🎯 Purpose

Move your Docker containers from local laptop development to a cloud-based development environment in AKS, allowing for:
- Consistent development environment across team members
- Better resource utilization than local development
- Integration testing with cloud services
- Easier collaboration and debugging

## 📁 Files

- `msdp-dev-services.yaml` - Kubernetes manifests for all MSDP services
- `deploy-msdp-dev.sh` - Management script for deploying and managing services
- `README.md` - This documentation

## 🚀 Quick Start

### 1. Update Docker Images

First, update the image names in `msdp-dev-services.yaml` to point to your actual Docker registry:

```yaml
# Replace these placeholder images with your actual images
image: your-registry/msdp-api-gateway:latest
image: your-registry/msdp-location-service:latest
# ... etc
```

### 2. Deploy Services

```bash
# Deploy all services
./deploy-msdp-dev.sh deploy

# Check status
./deploy-msdp-dev.sh status
```

### 3. Access Your Services

**Option A: Port Forwarding (for development)**
```bash
# Forward API Gateway to localhost:3000
./deploy-msdp-dev.sh port-forward api-gateway 3000

# Forward Location Service to localhost:3001
./deploy-msdp-dev.sh port-forward location-service 3001
```

**Option B: Ingress (for external access)**
- Services are available at: `https://msdp-dev.aztech-msdp.com/api/{service}`
- Update the hostname in the ingress to match your domain

## 🔧 Management Commands

```bash
# Deploy all services
./deploy-msdp-dev.sh deploy

# Check service status
./deploy-msdp-dev.sh status

# Get logs for a service
./deploy-msdp-dev.sh logs api-gateway

# Update a service with new image
./deploy-msdp-dev.sh update api-gateway your-registry/msdp-api-gateway:v1.2.3

# Scale a service
./deploy-msdp-dev.sh scale api-gateway 2

# Port forward to access locally
./deploy-msdp-dev.sh port-forward api-gateway 3000

# Clean up all services
./deploy-msdp-dev.sh cleanup
```

## 🏗️ Services Deployed

| Service | Port | Purpose |
|---------|------|---------|
| API Gateway | 3000 | Main API entry point |
| Location Service | 3001 | Geographic data and locations |
| Merchant Service | 3002 | VendaBuddy marketplace |
| User Service | 3003 | User authentication |
| Order Service | 3006 | Order processing |
| Payment Service | 3007 | Payment processing |

## 🚀 **FAST Development Workflow with Skaffold**

### 🎯 **No More Docker Build/Push Cycles!**

Use Skaffold for lightning-fast development:

```bash
# Start development mode (watches files, auto-syncs changes)
./dev-with-skaffold.sh dev

# Your services are now running with:
# ✅ Automatic file sync (no rebuilds needed)
# ✅ Port forwarding to localhost
# ✅ Real-time log streaming
# ✅ Hot reload for code changes
```

### 🔄 **Traditional Development Workflow (Slower)**

If you prefer the traditional approach:

### 1. Build and Push Images

```bash
# Build your Docker image locally
docker build -t your-registry/msdp-api-gateway:latest .

# Push to registry
docker push your-registry/msdp-api-gateway:latest
```

### 2. Update Service in Kubernetes

```bash
# Update the service with new image
./deploy-msdp-dev.sh update api-gateway your-registry/msdp-api-gateway:latest
```

### 3. Test Your Changes

```bash
# Port forward to test locally
./deploy-msdp-dev.sh port-forward api-gateway 3000

# Or access via ingress
curl https://msdp-dev.aztech-msdp.com/api/gateway/health
```

### 4. Check Logs

```bash
# View service logs
./deploy-msdp-dev.sh logs api-gateway

# Or use kubectl directly
kubectl logs -n msdp-dev -l app=msdp-api-gateway -f
```

## 🌐 Network Access

### Internal Service Communication
Services can communicate with each other using Kubernetes DNS:
- `http://msdp-api-gateway.msdp-dev.svc.cluster.local:3000`
- `http://msdp-location-service.msdp-dev.svc.cluster.local:3001`
- etc.

### External Access
1. **Port Forwarding**: For development and debugging
2. **Ingress**: For external API access (configure DNS)
3. **LoadBalancer**: For production-like external access

## 📊 Resource Limits

Each service is configured with:
- **Requests**: 256Mi memory, 250m CPU
- **Limits**: 512Mi memory, 500m CPU

Adjust these in `msdp-dev-services.yaml` based on your needs.

## 🔍 Monitoring

```bash
# Check pod status
kubectl get pods -n msdp-dev

# Check resource usage
kubectl top pods -n msdp-dev

# Describe a pod for troubleshooting
kubectl describe pod -n msdp-dev <pod-name>
```

## 🧹 Cleanup

When you're done with development:

```bash
# Remove all services
./deploy-msdp-dev.sh cleanup

# Or manually delete the namespace
kubectl delete namespace msdp-dev
```

## 🔧 Customization

### Adding Environment Variables

Edit `msdp-dev-services.yaml` and add environment variables to any service:

```yaml
env:
- name: DATABASE_URL
  value: "postgresql://user:pass@host:5432/db"
- name: REDIS_URL
  value: "redis://redis:6379"
```

### Adding ConfigMaps or Secrets

```bash
# Create a ConfigMap for configuration
kubectl create configmap msdp-config -n msdp-dev --from-file=config.json

# Create a Secret for sensitive data
kubectl create secret generic msdp-secrets -n msdp-dev --from-literal=api-key=your-secret-key
```

Then reference them in your deployments:

```yaml
envFrom:
- configMapRef:
    name: msdp-config
- secretRef:
    name: msdp-secrets
```

## 🚨 Troubleshooting

### Pod Not Starting
```bash
# Check pod events
kubectl describe pod -n msdp-dev <pod-name>

# Check logs
kubectl logs -n msdp-dev <pod-name>
```

### Service Not Accessible
```bash
# Check service endpoints
kubectl get endpoints -n msdp-dev

# Test service connectivity
kubectl run test-pod -n msdp-dev --image=curlimages/curl -it --rm -- /bin/sh
```

### Image Pull Issues
- Ensure your Docker registry is accessible from AKS
- Check if authentication is required for your registry
- Verify the image name and tag are correct

This setup gives you a complete cloud-based development environment for your MSDP services! 🎉
