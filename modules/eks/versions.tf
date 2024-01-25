terraform {
  required_version = ">= 1.4.0"
  required_providers {
    aws = {
      source                = "hashicorp/aws"
      version               = "~> 5.0"
      configuration_aliases = [aws.eks]
    }
    null = {
      source  = "hashicorp/null"
      version = ">= 3.1.0"
    }
    tls = {
      source  = "hashicorp/tls"
      version = ">= 4.0"

    }
    local = {
      source  = "hashicorp/local"
      version = ">= 2.2.0"
    }
  }
}

provider "aws" {
  region = var.region
  default_tags {
    tags = var.tags
  }
  ignore_tags {
    keys = var.ignore_tags
  }
}

provider "aws" {
  alias  = "eks"
  region = var.region
  default_tags {
    tags = var.tags
  }
  ignore_tags {
    keys = var.ignore_tags
  }
  assume_role {
    role_arn = var.create_eks_role_arn
  }
}
