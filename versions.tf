terraform {
  required_version = ">= 1.4.0"
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = ">= 4.0"
    }
    local = {
      source  = "hashicorp/local"
      version = ">= 2.2.0"
    }
    tls = {
      source  = "hashicorp/tls"
      version = ">= 3.4.0"
    }
    time = {
      source  = "hashicorp/time"
      version = ">= 0.9.1"
    }
  }
}

provider "aws" {
  region = var.region
  default_tags {
    tags = var.tags
  }
}


provider "aws" {
  alias  = "eks"
  region = var.region
  default_tags {
    tags = var.tags
  }

  assume_role {
    role_arn = "${aws_iam_role.create_eks_role.arn}${time_sleep.create_eks_role_10_seconds.id == "nil" ? "" : ""}"
  }
}
