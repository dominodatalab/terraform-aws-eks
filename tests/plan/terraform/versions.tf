provider "aws" {
  region = var.region
  ignore_tags {
    keys = var.ignore_tags
  }
}

terraform {
  required_version = ">= 1.4.0"
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }
}
