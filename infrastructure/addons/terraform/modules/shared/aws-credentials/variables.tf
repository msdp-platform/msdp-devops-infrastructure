# Shared AWS Credentials Module Variables

variable "enabled" {
  description = "Whether to create the AWS credentials secret"
  type        = bool
  default     = true
}

variable "secret_name" {
  description = "Name of the Kubernetes secret to create"
  type        = string
  default     = "aws-credentials"
}

variable "namespace" {
  description = "Kubernetes namespace where the secret will be created"
  type        = string
}

variable "aws_access_key_id" {
  description = "AWS access key ID"
  type        = string
  sensitive   = true
}

variable "aws_secret_access_key" {
  description = "AWS secret access key"
  type        = string
  sensitive   = true
}

variable "aws_region" {
  description = "AWS region"
  type        = string
  default     = "us-east-1"
}

variable "secret_format" {
  description = "Format of the secret data (standard or crossplane)"
  type        = string
  default     = "standard"
  
  validation {
    condition     = contains(["standard", "crossplane"], var.secret_format)
    error_message = "Secret format must be either 'standard' or 'crossplane'."
  }
}

variable "labels" {
  description = "Additional labels to apply to the secret"
  type        = map(string)
  default     = {}
}
