terraform {
  required_version = ">= 1.0"
  required_providers {
    null = {
      source  = "hashicorp/null"
      version = ">= 3.1.0"
    }
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
    random = {
      source  = "hashicorp/random"
      version = "~> 3.0"
    }
  }
}

provider "aws" {
  default_tags {
    tags = merge(var.tags, var.partner_tags)
  }
  ignore_tags {
    keys = var.ignore_tags
  }

  use_fips_endpoint = var.use_fips_endpoint
}
