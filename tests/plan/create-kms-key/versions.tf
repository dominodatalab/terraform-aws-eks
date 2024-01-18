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
  ignore_tags {
    keys = var.ignore_tags
  }
}


provider "aws" {
  region = "us-east-1"
  alias  = "us-east-1"
  ignore_tags {
    keys = var.ignore_tags
  }
}
