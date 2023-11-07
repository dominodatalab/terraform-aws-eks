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
}


provider "aws" {
  region = var.domino_cur.region
  alias  = "domino_cur_region"
}
