variable "project" { type = string, default = "msdp" }
variable "env" { type = string, default = "dev" }
variable "region" { type = string, default = "eu-west-1" }
variable "lambda_zip_path" { type = string, default = "../../msdp-location-service/artifacts/location.zip" }
variable "cors_allowed_origins" { type = list(string), default = ["http://localhost:3010"] }
