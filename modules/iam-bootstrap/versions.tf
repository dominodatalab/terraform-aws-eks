terraform {
  required_version = ">= 1.4.0"
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = ">= 4.0"
    }
  }
}

provider "aws" {
  region = var.region
  default_tags {
    tags = merge(var.tags, var.partner_tags)
  }
  ignore_tags {
    keys = var.ignore_tags
  }

  use_fips_endpoint = var.use_fips_endpoint
}
