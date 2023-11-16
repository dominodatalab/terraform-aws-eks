terraform {
  required_version = ">= 1.0"
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5"
      configuration_aliases = [ aws.domino_cur_region ]
    }
    archive = {
      source  = "hashicorp/archive"
      version = "~> 2"
    }
  }
}
