terraform {
  required_version = ">= 1.7.0"
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5"
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
  ignore_tags {
    keys = var.ignore_tags
  }

  use_fips_endpoint = var.use_fips_endpoint
}

provider "aws" {
  region = strcontains(var.region, "us-gov") ? "us-gov-east-1" : "us-east-1"
  alias  = "us-east-1"
  default_tags {
    tags = var.tags
  }
  ignore_tags {
    keys = var.ignore_tags
  }

  use_fips_endpoint = var.use_fips_endpoint
}

provider "aws" {
  region = local.kms_region
  alias  = "kms"
  default_tags {
    tags = var.tags
  }
  ignore_tags {
    keys = var.ignore_tags
  }

  use_fips_endpoint = var.use_fips_endpoint
}
