terraform {
  required_version = ">= 1.0"
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }
}

provider "aws" {
  region = var.region

  ignore_tags {
    keys = var.ignore_tags
  }
  use_fips_endpoint = var.use_fips_endpoint
}
