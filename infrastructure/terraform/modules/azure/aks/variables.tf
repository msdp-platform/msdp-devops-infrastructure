variable "org" { type = string }
variable "env" { type = string }
variable "cloud" { type = string }
variable "region" { type = string }
variable "resource_group_name" { type = string }
variable "cluster_name" { type = string }
variable "subnet_id" { type = string }
variable "k8s_version" { type = string }
variable "node_pool" {
  type = object({
    name        = string
    vm_size     = string
    node_count  = number
    min_count   = number
    max_count   = number
  })
}
variable "tags" { type = map(string) default = {} }

