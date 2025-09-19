# Shared AWS Credentials Module
# This module creates AWS credentials secrets for cross-cloud access
# Used by cert-manager, external-dns, and crossplane

terraform {
  required_providers {
    kubernetes = {
      source  = "hashicorp/kubernetes"
      version = "~> 2.24"
    }
  }
}

# Create AWS credentials secret
resource "kubernetes_secret" "aws_credentials" {
  count = var.enabled && var.aws_access_key_id != "" && var.aws_secret_access_key != "" ? 1 : 0

  metadata {
    name      = var.secret_name
    namespace = var.namespace
    
    labels = merge(
      var.labels,
      {
        "app.kubernetes.io/managed-by" = "terraform"
        "app.kubernetes.io/component"  = "aws-credentials"
      }
    )
  }

  data = var.secret_format == "crossplane" ? {
    creds = jsonencode({
      accessKeyId     = var.aws_access_key_id
      secretAccessKey = var.aws_secret_access_key
      region          = var.aws_region
    })
  } : {
    aws-access-key-id     = var.aws_access_key_id
    aws-secret-access-key = var.aws_secret_access_key
  }

  type = "Opaque"
}
