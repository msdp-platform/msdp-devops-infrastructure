# Shared AWS Credentials Module Outputs

output "secret_name" {
  description = "Name of the created AWS credentials secret"
  value       = var.enabled && length(kubernetes_secret.aws_credentials) > 0 ? kubernetes_secret.aws_credentials[0].metadata[0].name : null
}

output "secret_namespace" {
  description = "Namespace of the created AWS credentials secret"
  value       = var.enabled && length(kubernetes_secret.aws_credentials) > 0 ? kubernetes_secret.aws_credentials[0].metadata[0].namespace : null
}

output "secret_exists" {
  description = "Whether the AWS credentials secret was created"
  value       = var.enabled && length(kubernetes_secret.aws_credentials) > 0
}
