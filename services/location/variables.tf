variable "project" { type = string, default = "msdp" }
variable "env" { type = string, default = "dev" }
variable "region" { type = string, default = "eu-west-1" }
variable "lambda_image_uri" { type = string, default = "" }
variable "cors_allowed_origins" { type = list(string), default = ["http://localhost:3010"] }

