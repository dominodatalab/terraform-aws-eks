provider "aws" {
  region = var.region
  ignore_tags {
    keys = var.ignore_tags
  }

  use_fips_endpoint = var.use_fips_endpoint
}

terraform {
  required_version = ">= 1.4.0"
  required_providers {
    aws = {
      source = "hashicorp/aws"
      # pinned until https://github.com/hashicorp/terraform-provider-aws/pull/39328 is released
      version = "<5.67.0"
    }
  }
}
