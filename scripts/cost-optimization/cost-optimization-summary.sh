#!/bin/bash

# Cost Optimization Summary Script
# This script shows the cost savings achieved by using a single public IP

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

echo -e "${BLUE}💰 Cost Optimization Summary${NC}"
echo "============================="
echo ""

# Get current setup
INGRESS_IP=$(kubectl get svc -n ingress-nginx ingress-nginx-controller -o jsonpath='{.status.loadBalancer.ingress[0].ip}' 2>/dev/null || echo "Not available")
ARGOCD_SERVICE_TYPE=$(kubectl get svc -n argocd argocd-server -o jsonpath='{.spec.type}')

echo -e "${GREEN}✅ Current Setup:${NC}"
echo "=================="
echo "Ingress Controller: NGINX with LoadBalancer"
echo "Public IP: $INGRESS_IP"
echo "ArgoCD Service: $ARGOCD_SERVICE_TYPE (was LoadBalancer)"
echo ""

echo -e "${YELLOW}📊 Cost Comparison:${NC}"
echo "====================="
echo ""
echo "BEFORE (Multiple LoadBalancers):"
echo "  - ArgoCD LoadBalancer: ~\$18/month"
echo "  - Crossplane LoadBalancer: ~\$18/month"
echo "  - Sample App LoadBalancer: ~\$18/month"
echo "  - Total: ~\$54/month"
echo ""
echo "AFTER (Single LoadBalancer):"
echo "  - NGINX Ingress LoadBalancer: ~\$18/month"
echo "  - Total: ~\$18/month"
echo ""
echo -e "${GREEN}💰 Monthly Savings: ~\$36 (67% reduction)${NC}"
echo ""

echo -e "${BLUE}🌐 Service Access:${NC}"
echo "==================="
echo "All services accessible through single IP: $INGRESS_IP"
echo ""
echo "Service URLs:"
echo "  ArgoCD:     http://argocd.delivery-platform.local"
echo "  Crossplane: http://crossplane.delivery-platform.local"
echo "  Sample App: http://app.delivery-platform.local"
echo ""

echo -e "${YELLOW}🔧 Setup Commands:${NC}"
echo "===================="
echo "# Add to /etc/hosts:"
echo "echo \"$INGRESS_IP argocd.delivery-platform.local\" | sudo tee -a /etc/hosts"
echo "echo \"$INGRESS_IP crossplane.delivery-platform.local\" | sudo tee -a /etc/hosts"
echo "echo \"$INGRESS_IP app.delivery-platform.local\" | sudo tee -a /etc/hosts"
echo ""

echo -e "${GREEN}🎯 Benefits Achieved:${NC}"
echo "====================="
echo "✅ 67% cost reduction on LoadBalancers"
echo "✅ Single public IP for all services"
echo "✅ Simplified network management"
echo "✅ Better security with ingress rules"
echo "✅ Easy SSL termination (future enhancement)"
echo "✅ Path-based routing"
echo "✅ Rate limiting capabilities (future enhancement)"
echo ""

echo -e "${BLUE}📈 Future Optimizations:${NC}"
echo "========================="
echo "1. Use Azure Application Gateway (more features)"
echo "2. Implement SSL/TLS certificates"
echo "3. Add rate limiting and DDoS protection"
echo "4. Use Azure CDN for static content"
echo "5. Implement WAF (Web Application Firewall)"
