#!/bin/bash
# GitHub OIDC Setup for AWS Authentication
# This script sets up GitHub OIDC provider and IAM roles for secure AWS access

set -e

# Configuration
AWS_PROFILE="${AWS_PROFILE:-AWSAdministratorAccess-319422413814}"
AWS_REGION="${AWS_REGION:-us-west-2}"
GITHUB_ORG="${GITHUB_ORG:-msdp-platform}"
GITHUB_REPO="${GITHUB_REPO:-msdp-devops-infrastructure}"
OIDC_PROVIDER_NAME="github-actions-oidc"
ROLE_NAME_PREFIX="GitHubActions"

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Logging functions
log_info() {
    echo -e "${BLUE}[INFO]${NC} $1"
}

log_success() {
    echo -e "${GREEN}[SUCCESS]${NC} $1"
}

log_warning() {
    echo -e "${YELLOW}[WARNING]${NC} $1"
}

log_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

# Check if AWS CLI is configured
check_aws_config() {
    log_info "Checking AWS configuration..."
    
    if ! aws sts get-caller-identity --profile "$AWS_PROFILE" >/dev/null 2>&1; then
        log_error "AWS profile '$AWS_PROFILE' not configured or invalid"
        log_info "Please configure your AWS SSO profile first:"
        log_info "aws configure sso --profile $AWS_PROFILE"
        exit 1
    fi
    
    ACCOUNT_ID=$(aws sts get-caller-identity --profile "$AWS_PROFILE" --query Account --output text)
    log_success "AWS profile configured. Account ID: $ACCOUNT_ID"
}

# Create GitHub OIDC Identity Provider
create_oidc_provider() {
    log_info "Creating GitHub OIDC Identity Provider..."
    
    # Check if OIDC provider already exists
    if aws iam get-open-id-connect-provider --open-id-connect-provider-arn "arn:aws:iam::$ACCOUNT_ID:oidc-provider/token.actions.githubusercontent.com" --profile "$AWS_PROFILE" >/dev/null 2>&1; then
        log_warning "GitHub OIDC provider already exists"
        return 0
    fi
    
    # Create OIDC provider
    aws iam create-open-id-connect-provider \
        --url "https://token.actions.githubusercontent.com" \
        --client-id-list "sts.amazonaws.com" \
        --thumbprint-list "6938fd4d98bab03faadb97b34396831e3780aea1" \
        --profile "$AWS_PROFILE" \
        --region "$AWS_REGION"
    
    log_success "GitHub OIDC provider created"
}

# Create IAM role for GitHub Actions
create_github_actions_role() {
    local role_name="$ROLE_NAME_PREFIX-Role"
    local policy_name="$ROLE_NAME_PREFIX-Policy"
    
    log_info "Creating IAM role for GitHub Actions..."
    
    # Trust policy for GitHub Actions
    cat > /tmp/github-trust-policy.json << EOF
{
    "Version": "2012-10-17",
    "Statement": [
        {
            "Effect": "Allow",
            "Principal": {
                "Federated": "arn:aws:iam::$ACCOUNT_ID:oidc-provider/token.actions.githubusercontent.com"
            },
            "Action": "sts:AssumeRoleWithWebIdentity",
            "Condition": {
                "StringEquals": {
                    "token.actions.githubusercontent.com:aud": "sts.amazonaws.com"
                },
                "StringLike": {
                    "token.actions.githubusercontent.com:sub": "repo:$GITHUB_ORG/$GITHUB_REPO:*"
                }
            }
        }
    ]
}
EOF

    # Create IAM role
    if aws iam get-role --role-name "$role_name" --profile "$AWS_PROFILE" >/dev/null 2>&1; then
        log_warning "IAM role '$role_name' already exists"
    else
        aws iam create-role \
            --role-name "$role_name" \
            --assume-role-policy-document file:///tmp/github-trust-policy.json \
            --profile "$AWS_PROFILE"
        log_success "IAM role '$role_name' created"
    fi

    # Create IAM policy for GitHub Actions
    cat > /tmp/github-actions-policy.json << EOF
{
    "Version": "2012-10-17",
    "Statement": [
        {
            "Effect": "Allow",
            "Action": [
                "eks:*",
                "ec2:*",
                "iam:*",
                "vpc:*",
                "sqs:*",
                "events:*",
                "cloudwatch:*",
                "logs:*",
                "route53:*",
                "acm:*",
                "secretsmanager:*",
                "ssm:*",
                "s3:*",
                "rds:*",
                "elasticloadbalancing:*",
                "autoscaling:*",
                "application-autoscaling:*",
                "kms:*",
                "sts:*"
            ],
            "Resource": "*"
        }
    ]
}
EOF

    # Attach policy to role
    if aws iam get-policy --policy-arn "arn:aws:iam::$ACCOUNT_ID:policy/$policy_name" --profile "$AWS_PROFILE" >/dev/null 2>&1; then
        log_warning "IAM policy '$policy_name' already exists"
    else
        aws iam create-policy \
            --policy-name "$policy_name" \
            --policy-document file:///tmp/github-actions-policy.json \
            --profile "$AWS_PROFILE"
        log_success "IAM policy '$policy_name' created"
    fi

    # Attach policy to role
    aws iam attach-role-policy \
        --role-name "$role_name" \
        --policy-arn "arn:aws:iam::$ACCOUNT_ID:policy/$policy_name" \
        --profile "$AWS_PROFILE"
    
    log_success "Policy attached to role"
    
    # Clean up temporary files
    rm -f /tmp/github-trust-policy.json /tmp/github-actions-policy.json
}

# Create Terraform backend S3 bucket
create_terraform_backend() {
    local bucket_name="msdp-terraform-state-$(date +%s)"
    
    log_info "Creating Terraform backend S3 bucket..."
    
    # Create S3 bucket
    aws s3 mb "s3://$bucket_name" --profile "$AWS_PROFILE" --region "$AWS_REGION"
    
    # Enable versioning
    aws s3api put-bucket-versioning \
        --bucket "$bucket_name" \
        --versioning-configuration Status=Enabled \
        --profile "$AWS_PROFILE"
    
    # Enable server-side encryption
    aws s3api put-bucket-encryption \
        --bucket "$bucket_name" \
        --server-side-encryption-configuration '{
            "Rules": [
                {
                    "ApplyServerSideEncryptionByDefault": {
                        "SSEAlgorithm": "AES256"
                    }
                }
            ]
        }' \
        --profile "$AWS_PROFILE"
    
    # Block public access
    aws s3api put-public-access-block \
        --bucket "$bucket_name" \
        --public-access-block-configuration "BlockPublicAcls=true,IgnorePublicAcls=true,BlockPublicPolicy=true,RestrictPublicBuckets=true" \
        --profile "$AWS_PROFILE"
    
    log_success "Terraform backend bucket created: $bucket_name"
    echo "TERRAFORM_BUCKET_NAME=$bucket_name" >> /tmp/aws-config.env
}

# Generate GitHub Actions configuration
generate_github_config() {
    log_info "Generating GitHub Actions configuration..."
    
    cat > /tmp/github-actions-config.md << EOF
# GitHub Actions OIDC Configuration

## Required GitHub Secrets

Add these secrets to your GitHub repository:

\`\`\`
AWS_ROLE_ARN=arn:aws:iam::$ACCOUNT_ID:role/$ROLE_NAME_PREFIX-Role
AWS_REGION=$AWS_REGION
TERRAFORM_BUCKET_NAME=$(cat /tmp/aws-config.env | grep TERRAFORM_BUCKET_NAME | cut -d'=' -f2)
\`\`\`

## GitHub Actions Workflow Configuration

Your GitHub Actions workflow should use OIDC authentication:

\`\`\`yaml
- name: Configure AWS credentials
  uses: aws-actions/configure-aws-credentials@v4
  with:
    role-to-assume: \${{ secrets.AWS_ROLE_ARN }}
    aws-region: \${{ secrets.AWS_REGION }}
\`\`\`

## Terraform Backend Configuration

Update your Terraform backend configuration:

\`\`\`hcl
terraform {
  backend "s3" {
    bucket = "$(cat /tmp/aws-config.env | grep TERRAFORM_BUCKET_NAME | cut -d'=' -f2)"
    key    = "dev/eks-blueprint/terraform.tfstate"
    region = "$AWS_REGION"
  }
}
\`\`\`
EOF

    log_success "GitHub Actions configuration generated"
    cat /tmp/github-actions-config.md
}

# Main execution
main() {
    log_info "Starting GitHub OIDC setup for AWS..."
    log_info "Using AWS profile: $AWS_PROFILE"
    log_info "Using AWS region: $AWS_REGION"
    log_info "GitHub org/repo: $GITHUB_ORG/$GITHUB_REPO"
    
    check_aws_config
    create_oidc_provider
    create_github_actions_role
    create_terraform_backend
    generate_github_config
    
    log_success "GitHub OIDC setup completed successfully!"
    log_info "Next steps:"
    log_info "1. Add the secrets to your GitHub repository"
    log_info "2. Update your Terraform backend configuration"
    log_info "3. Update your GitHub Actions workflow to use OIDC"
}

# Run main function
main "$@"
