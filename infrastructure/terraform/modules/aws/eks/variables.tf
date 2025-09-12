variable "org" {
  type = string
}

variable "env" {
  type = string
}

variable "cloud" {
  type = string
}

variable "region" {
  type = string
}

variable "cluster_name" {
  type = string
}

variable "vpc_id" {
  type = string
}

variable "private_subnet_ids" {
  type = list(string)
}

variable "k8s_version" {
  type = string
}
variable "node_group" {
  type = object({
    name          = string
    instance_type = string
    desired_size  = number
    min_size      = number
    max_size      = number
  })
}
variable "tags" {
  type    = map(string)
  default = {}
}

