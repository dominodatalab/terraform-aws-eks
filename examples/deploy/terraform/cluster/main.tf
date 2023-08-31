data "terraform_remote_state" "infra" {
  backend = "local"

  config = {
    path = "${path.module}/../infra.tfstate"
  }
}

locals {
  infra = data.terraform_remote_state.infra.outputs.infra
  eks   = var.eks != null ? var.eks : local.infra.eks
  kms   = var.kms_info != null ? var.kms_info : local.infra.kms
}

module "eks" {
  source    = "./../../../../modules/eks"
  deploy_id = local.infra.deploy_id
  region    = local.infra.region

  ssh_key             = local.infra.ssh_key
  node_iam_policies   = local.infra.node_iam_policies
  efs_security_group  = local.infra.efs_security_group
  eks                 = local.eks
  network_info        = local.infra.network
  kms_info            = local.kms
  bastion_info        = local.infra.bastion
  create_eks_role_arn = local.infra.create_eks_role_arn
  tags                = local.infra.tags

}

provider "aws" {
  region = var.region
  default_tags {
    tags = var.tags
  }
}

terraform {
  required_version = ">= 1.4.0"
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = ">= 4.0"
    }
  }
}
