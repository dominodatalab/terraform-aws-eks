module "infra" {
  source = "./../../../../modules/infra"

  deploy_id              = var.deploy_id
  additional_node_groups = var.additional_node_groups
  bastion                = var.bastion
  default_node_groups    = var.default_node_groups

  network          = var.network
  eks              = var.eks
  kms              = var.kms
  storage          = var.storage
  region           = var.region
  ssh_pvt_key_path = var.ssh_pvt_key_path
  tags             = var.tags
  ignore_tags      = var.ignore_tags
  domino_cur       = var.domino_cur
}


provider "aws" {
  region = var.region

  ignore_tags {
    keys = var.ignore_tags
  }
}

terraform {
  required_version = ">= 1.6.0"
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }
}
