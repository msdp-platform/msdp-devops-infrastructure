terraform {
  required_version = ">= 1.6.0"
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = ">= 5.0"
    }
  }
}

provider "aws" {
  region = var.region
}

resource "aws_apigatewayv2_api" "http" {
  name          = "${var.project}-location-${var.env}"
  protocol_type = "HTTP"
}

