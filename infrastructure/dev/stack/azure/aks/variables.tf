variable "org" { type = string }
variable "env" { type = string }
variable "region" { type = string }
variable "resource_group_name" { type = string }
variable "cluster_name" { type = string }
variable "subnet_id" { type = string }
variable "k8s_version" { type = string }
variable "node_pool_name" { type = string }
variable "node_vm_size" { type = string }
variable "node_count" { type = number }
variable "node_min" { type = number }
variable "node_max" { type = number }
variable "tags" { type = map(string) default = {} }

