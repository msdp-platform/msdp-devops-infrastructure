module "aks" {
  source = "../../../../terraform/modules/azure/aks"

  org                 = var.org
  env                 = var.env
  cloud               = "azure"
  region              = var.region
  resource_group_name = var.resource_group_name
  cluster_name        = var.cluster_name
  subnet_id           = var.subnet_id
  k8s_version         = var.k8s_version
  node_pool = {
    name       = var.node_pool_name
    vm_size    = var.node_vm_size
    node_count = var.node_count
    min_count  = var.node_min
    max_count  = var.node_max
  }
  tags = var.tags
}

output "cluster_name" {
  value = module.aks.cluster_name
}

output "kube_config" {
  value     = module.aks.kube_config
  sensitive = true
}