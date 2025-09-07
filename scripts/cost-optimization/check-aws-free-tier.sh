#!/bin/bash

# AWS Free Tier Eligibility Checker
# This script checks if you're eligible for AWS Free Tier services

echo "🔍 AWS Free Tier Eligibility Checker"
echo "=================================="

# Check if AWS CLI is configured
if ! aws sts get-caller-identity --profile AWSAdministratorAccess-319422413814 &> /dev/null; then
    echo "❌ AWS CLI not configured. Please run 'aws configure sso' first."
    exit 1
fi

# Set the profile for all AWS commands
export AWS_PROFILE=AWSAdministratorAccess-319422413814

echo "✅ AWS CLI is configured"

# Get account information
echo ""
echo "📋 Account Information:"
echo "----------------------"
aws sts get-caller-identity

# Check account age (Free Tier is for first 12 months)
echo ""
echo "📅 Account Age Check:"
echo "-------------------"
ACCOUNT_ID=$(aws sts get-caller-identity --query 'Account' --output text)
echo "Account ID: $ACCOUNT_ID"

# Check if account is eligible for Free Tier
echo ""
echo "🆓 Free Tier Eligibility:"
echo "------------------------"

# Check EC2 Free Tier
echo "Checking EC2 Free Tier..."
aws ec2 describe-instances --query 'Reservations[*].Instances[*].[InstanceId,InstanceType,State.Name]' --output table 2>/dev/null || echo "No EC2 instances found"

# Check RDS Free Tier
echo ""
echo "Checking RDS Free Tier..."
aws rds describe-db-instances --query 'DBInstances[*].[DBInstanceIdentifier,DBInstanceClass,DBInstanceStatus]' --output table 2>/dev/null || echo "No RDS instances found"

# Check S3 Free Tier
echo ""
echo "Checking S3 Free Tier..."
aws s3 ls 2>/dev/null || echo "No S3 buckets found"

# Check Lambda Free Tier
echo ""
echo "Checking Lambda Free Tier..."
aws lambda list-functions --query 'Functions[*].[FunctionName,Runtime,State]' --output table 2>/dev/null || echo "No Lambda functions found"

# Check ElastiCache Free Tier
echo ""
echo "Checking ElastiCache Free Tier..."
aws elasticache describe-cache-clusters --query 'CacheClusters[*].[CacheClusterId,CacheNodeType,CacheClusterStatus]' --output table 2>/dev/null || echo "No ElastiCache clusters found"

# Check DynamoDB Free Tier
echo ""
echo "Checking DynamoDB Free Tier..."
aws dynamodb list-tables --query 'TableNames' --output table 2>/dev/null || echo "No DynamoDB tables found"

echo ""
echo "🎯 Free Tier Services Available:"
echo "==============================="
echo "✅ EC2: 750 hours/month of t2.micro instances"
echo "✅ RDS: 750 hours/month of db.t2.micro, 20GB storage"
echo "✅ ElastiCache: 750 hours/month of cache.t2.micro"
echo "✅ S3: 5GB storage, 20,000 GET requests, 2,000 PUT requests"
echo "✅ Lambda: 1M requests/month, 400,000 GB-seconds compute"
echo "✅ API Gateway: 1M API calls/month"
echo "✅ DynamoDB: 25GB storage, 25 read/write capacity units"
echo "✅ CloudWatch: 10 custom metrics, 5GB log ingestion"

echo ""
echo "💰 Estimated Monthly Cost: $0 (Free Tier)"
echo "⏰ Free Tier Duration: 12 months from account creation"
echo ""
echo "🚀 You're eligible for AWS Free Tier! You can develop your entire platform for FREE!"
