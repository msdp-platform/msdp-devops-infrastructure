#!/bin/bash

# Cost Optimization Script for Multi-Cloud Delivery Platform
# Helps manage costs across AWS, GCP, and Azure

set -e

echo "💰 Multi-Cloud Cost Optimization Tool"
echo "====================================="

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Function to print colored output
print_status() {
    echo -e "${BLUE}[INFO]${NC} $1"
}

print_success() {
    echo -e "${GREEN}[SUCCESS]${NC} $1"
}

print_warning() {
    echo -e "${YELLOW}[WARNING]${NC} $1"
}

print_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

# Function to check free tier usage
check_free_tier_usage() {
    print_status "Checking free tier usage across cloud providers..."
    
    echo ""
    echo "🆓 Free Tier Status:"
    echo "==================="
    
    # AWS Free Tier Check
    if command -v aws &> /dev/null; then
        print_status "AWS Free Tier Usage:"
        echo "  • EC2: Check AWS Console > Billing > Free Tier"
        echo "  • RDS: Check AWS Console > RDS > Free Tier"
        echo "  • S3: Check AWS Console > S3 > Free Tier"
        echo "  • Lambda: Check AWS Console > Lambda > Free Tier"
    else
        print_warning "AWS CLI not installed. Install with: brew install awscli"
    fi
    
    # GCP Free Tier Check
    if command -v gcloud &> /dev/null; then
        print_status "GCP Free Tier Usage:"
        echo "  • Compute: Check GCP Console > Billing > Free Tier"
        echo "  • Cloud SQL: Check GCP Console > SQL > Free Tier"
        echo "  • Storage: Check GCP Console > Storage > Free Tier"
        echo "  • Functions: Check GCP Console > Functions > Free Tier"
    else
        print_warning "GCP CLI not installed. Install with: brew install google-cloud-sdk"
    fi
    
    # Azure Free Tier Check
    if command -v az &> /dev/null; then
        print_status "Azure Free Tier Usage:"
        echo "  • VMs: Check Azure Portal > Billing > Free Tier"
        echo "  • Database: Check Azure Portal > Database > Free Tier"
        echo "  • Storage: Check Azure Portal > Storage > Free Tier"
        echo "  • Functions: Check Azure Portal > Functions > Free Tier"
    else
        print_warning "Azure CLI not installed. Install with: brew install azure-cli"
    fi
}

# Function to estimate costs
estimate_costs() {
    print_status "Estimating monthly costs for different scenarios..."
    
    echo ""
    echo "💵 Cost Estimates:"
    echo "=================="
    
    echo ""
    echo "🆓 Free Tier Scenario (0-12 months):"
    echo "  AWS: $0/month (Free Tier)"
    echo "  GCP: $0/month (Free Tier + $300 credit)"
    echo "  Azure: $0/month (Free Tier + £100 credit)"
    echo "  Total: $0/month"
    
    echo ""
    echo "🔧 Development Scenario:"
    echo "  AWS: $26/month (db.t3.micro + cache.t3.micro)"
    echo "  GCP: $50/month (db-g1-small + Basic Redis)"
    echo "  Azure: $27/month (Basic B2s + Basic C1)"
    echo "  Total: $26-50/month"
    
    echo ""
    echo "🚀 Production Scenario:"
    echo "  AWS: $200/month (EKS + RDS + ElastiCache + S3)"
    echo "  GCP: $250/month (GKE + Cloud SQL + Memorystore + Storage)"
    echo "  Azure: $200/month (AKS + Database + Cache + Blob)"
    echo "  Total: $200-250/month"
}

# Function to show cost optimization tips
show_optimization_tips() {
    print_status "Cost optimization tips and strategies..."
    
    echo ""
    echo "💡 Cost Optimization Tips:"
    echo "========================="
    
    echo ""
    echo "1. 🆓 Maximize Free Tiers:"
    echo "   • Use AWS Free Tier for development (12 months)"
    echo "   • Rotate to GCP with $300 credit"
    echo "   • Use Azure £100 credit for extended testing"
    
    echo ""
    echo "2. ⏰ Resource Scheduling:"
    echo "   • Auto-stop resources after hours"
    echo "   • Shutdown on weekends"
    echo "   • Use spot instances for non-critical workloads"
    
    echo ""
    echo "3. 📊 Right-sizing:"
    echo "   • Start with smallest instances"
    echo "   • Monitor usage and scale up gradually"
    echo "   • Use auto-scaling for variable workloads"
    
    echo ""
    echo "4. 🏗️ Architecture Optimization:"
    echo "   • Use serverless where possible"
    echo "   • Implement caching to reduce database load"
    echo "   • Use CDN for static content"
    
    echo ""
    echo "5. 🔍 Monitoring:"
    echo "   • Set up billing alerts"
    echo "   • Monitor resource usage"
    echo "   • Regular cost reviews"
}

# Function to show free alternatives
show_free_alternatives() {
    print_status "Free alternatives and open source options..."
    
    echo ""
    echo "🆓 Free Alternatives:"
    echo "===================="
    
    echo ""
    echo "🗄️ Database:"
    echo "   • PostgreSQL: Docker container (FREE)"
    echo "   • Redis: Docker container (FREE)"
    echo "   • MongoDB: Docker container (FREE)"
    
    echo ""
    echo "☸️ Kubernetes:"
    echo "   • Minikube: Local development (FREE)"
    echo "   • Kind: Local development (FREE)"
    echo "   • MicroK8s: Local development (FREE)"
    
    echo ""
    echo "☁️ Cloud Services:"
    echo "   • Vercel: 100GB-hours/month (FREE)"
    echo "   • Netlify: 125K requests/month (FREE)"
    echo "   • Railway: $5 credit/month (FREE)"
    echo "   • Render: 750 hours/month (FREE)"
    
    echo ""
    echo "🔧 Development Tools:"
    echo "   • GitHub Actions: 2,000 minutes/month (FREE)"
    echo "   • Docker Hub: 1 private repo (FREE)"
    echo "   • Cloudflare: CDN + DNS (FREE)"
    echo "   • SendGrid: 100 emails/day (FREE)"
}

# Function to create cost monitoring setup
setup_cost_monitoring() {
    print_status "Setting up cost monitoring and alerts..."
    
    echo ""
    echo "📊 Cost Monitoring Setup:"
    echo "========================"
    
    echo ""
    echo "AWS Cost Monitoring:"
    echo "  # Set up billing alerts"
    echo "  aws budgets create-budget \\"
    echo "    --account-id YOUR_ACCOUNT_ID \\"
    echo "    --budget '{\"BudgetName\": \"Free-Tier-Monitor\", \"BudgetLimit\": {\"Amount\": \"10\", \"Unit\": \"USD\"}, \"TimeUnit\": \"MONTHLY\", \"BudgetType\": \"COST\"}'"
    
    echo ""
    echo "GCP Cost Monitoring:"
    echo "  # Set up billing alerts"
    echo "  gcloud billing budgets create \\"
    echo "    --billing-account=YOUR_BILLING_ACCOUNT \\"
    echo "    --display-name=\"Free-Tier-Monitor\" \\"
    echo "    --budget-amount=10USD"
    
    echo ""
    echo "Azure Cost Monitoring:"
    echo "  # Set up spending alerts"
    echo "  az consumption budget create \\"
    echo "    --budget-name \"Free-Tier-Monitor\" \\"
    echo "    --amount 10 \\"
    echo "    --category Cost \\"
    echo "    --time-grain Monthly"
}

# Function to show resource scheduling
show_resource_scheduling() {
    print_status "Resource scheduling for cost optimization..."
    
    echo ""
    echo "⏰ Resource Scheduling:"
    echo "======================"
    
    echo ""
    echo "Development Hours (9 AM - 6 PM):"
    echo "  • Auto-start resources"
    echo "  • Cost: Full price"
    
    echo ""
    echo "Non-Working Hours:"
    echo "  • Auto-stop resources"
    echo "  • Cost: Storage only (90% savings)"
    
    echo ""
    echo "Weekends:"
    echo "  • Complete shutdown"
    echo "  • Cost: Storage only (95% savings)"
    
    echo ""
    echo "Example AWS Lambda function for scheduling:"
    echo "  # Start instances at 9 AM"
    echo "  aws ec2 start-instances --instance-ids i-1234567890abcdef0"
    echo ""
    echo "  # Stop instances at 6 PM"
    echo "  aws ec2 stop-instances --instance-ids i-1234567890abcdef0"
}

# Main menu
show_menu() {
    echo ""
    echo "🎯 Cost Optimization Options:"
    echo "============================="
    echo "1. Check free tier usage"
    echo "2. Estimate costs"
    echo "3. Show optimization tips"
    echo "4. Show free alternatives"
    echo "5. Setup cost monitoring"
    echo "6. Show resource scheduling"
    echo "7. All options"
    echo "8. Exit"
    echo ""
    read -p "Choose an option (1-8): " choice
    
    case $choice in
        1) check_free_tier_usage ;;
        2) estimate_costs ;;
        3) show_optimization_tips ;;
        4) show_free_alternatives ;;
        5) setup_cost_monitoring ;;
        6) show_resource_scheduling ;;
        7) 
            check_free_tier_usage
            estimate_costs
            show_optimization_tips
            show_free_alternatives
            setup_cost_monitoring
            show_resource_scheduling
            ;;
        8) 
            print_success "Cost optimization analysis complete!"
            exit 0
            ;;
        *) 
            print_error "Invalid option. Please choose 1-8."
            show_menu
            ;;
    esac
}

# Run the script
echo ""
print_success "Multi-Cloud Cost Optimization Tool Ready!"
show_menu
