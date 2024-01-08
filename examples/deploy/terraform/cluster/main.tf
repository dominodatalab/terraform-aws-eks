data "terraform_remote_state" "infra" {
  backend = "local"

  config = {
    path = "${path.module}/../infra.tfstate"
  }
}

locals {
  infra = data.terraform_remote_state.infra.outputs.infra
  kms   = var.kms_info != null ? var.kms_info : local.infra.kms
}

module "eks" {
  source    = "./../../../../modules/eks"
  deploy_id = local.infra.deploy_id
  region    = local.infra.region

  ssh_key             = local.infra.ssh_key
  node_iam_policies   = local.infra.node_iam_policies
  efs_security_group  = local.infra.efs_security_group
  eks                 = var.eks
  network_info        = local.infra.network
  kms_info            = local.kms
  bastion_info        = local.infra.bastion
  create_eks_role_arn = local.infra.create_eks_role_arn
  tags                = local.infra.tags
}

# If you are enabling the IRSA configuration for external-dns.
# You will need to add the role created(module.irsa_external_dns.irsa_role) to
# the following annotation to the `external-dns` service account:
# `eks.amazonaws.com/role-arn: <<module.irsa_external_dns.irsa_role>>`


module "irsa_external_dns" {
  count               = var.irsa_external_dns != null && var.irsa_external_dns.enabled ? 1 : 0
  source              = "./../../../../modules/eks/submodules/irsa"
  use_cluster_odc_idp = false
  eks_info            = module.eks.info
  external_dns        = var.irsa_external_dns

  providers = {
    aws = aws.global
  }
}


module "irsa_policies" {
  count                   = var.irsa_policies != null ? 1 : 0
  source                  = "./../../../../modules/eks/submodules/irsa"
  use_cluster_odc_idp     = true
  eks_info                = module.eks.info
  additional_irsa_configs = var.irsa_policies
}

provider "aws" {
  region = local.infra.region
}

# Provider configuration for the account where the hosted zone is defined.
# Useful in configurations where accounts do not have a public hosted zone(i.e us-gov regions) and internet routing(public DNS)
# is instead defined in a different account. Note that there is additional configuration required.
provider "aws" {
  alias  = "global"
  region = local.infra.region
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
