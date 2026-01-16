data "terraform_remote_state" "infra" {
  backend = "local"

  config = {
    path = "${path.module}/../infra.tfstate"
  }
}

data "terraform_remote_state" "eks" {
  backend = "local"

  config = {
    path = "${path.module}/../cluster.tfstate"
  }
}



locals {
  infra = data.terraform_remote_state.infra.outputs.infra
  eks   = data.terraform_remote_state.eks.outputs.eks

}

module "nodes" {
  source = "./../../../../modules/nodes"
  region = local.infra.region

  ssh_key                = local.infra.ssh_key
  default_node_groups    = var.default_node_groups
  additional_node_groups = var.additional_node_groups
  system_node_group      = var.system_node_group
  eks_info               = local.eks
  network_info           = local.infra.network
  kms_info               = local.infra.kms
  tags                   = local.infra.tags
  ignore_tags            = local.infra.ignore_tags
  use_fips_endpoint      = var.use_fips_endpoint
}

provider "aws" {
  region = local.infra.region
  default_tags {
    tags = local.infra.tags
  }
  use_fips_endpoint = var.use_fips_endpoint
}

terraform {
  required_version = ">= 1.4.0"
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 6.0"
    }
  }
}
