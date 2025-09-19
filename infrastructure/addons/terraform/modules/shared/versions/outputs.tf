# Shared Version Management Outputs

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
