# Shared Version Management Outputs

# Core Version Collections
output "provider_versions" {
  description = "Terraform provider versions for all infrastructure"
  value       = local.provider_versions
}

output "kubernetes_versions" {
  description = "Kubernetes versions and compatibility info"
  value       = local.kubernetes_versions
}

output "tool_versions" {
  description = "Tool versions for CI/CD and development"
  value       = local.tool_versions
}

output "github_actions" {
  description = "GitHub Actions versions"
  value       = local.github_actions
}

output "image_versions" {
  description = "Container image versions for all addons"
  value       = local.image_versions
}

output "chart_versions" {
  description = "Helm chart versions for all addons"
  value       = local.chart_versions
}

output "helm_repositories" {
  description = "Helm repository URLs for all addons"
  value       = local.helm_repositories
}

# Individual addon outputs for easy access
output "cert_manager_images" {
  description = "Cert-Manager container image versions"
  value       = local.image_versions.cert_manager
}

output "cert_manager_chart_version" {
  description = "Cert-Manager Helm chart version"
  value       = local.chart_versions.cert_manager
}

output "external_dns_image_version" {
  description = "External DNS container image version"
  value       = local.image_versions.external_dns
}

output "external_dns_chart_version" {
  description = "External DNS Helm chart version"
  value       = local.chart_versions.external_dns
}
