variable "org" { type = string }
variable "env" { type = string }
variable "region" { type = string }
variable "cluster_name" { type = string }
variable "vpc_id" { type = string }
variable "private_subnet_ids" { type = list(string) }
variable "k8s_version" { type = string }
variable "node_group_name" { type = string }
variable "node_instance_type" { type = string }
variable "node_desired" { type = number }
variable "node_min" { type = number }
variable "node_max" { type = number }
variable "tags" {
  type = map(string)
  default = {}
}

  
variable "global_config_path" {
  type = string
  description = "Path to the global configuration YAML"
}

variable "env_config_path" {
  type = string
  description = "Path to the environment specific configuration YAML"
}
