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
  region = local.infra.region
  default_tags {
    tags = local.infra.tags
  }
  ignore_tags {
    keys = ["duration"]
  }
}
