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
  ignore_tags         = local.infra.ignore_tags
  use_fips_endpoint   = var.use_fips_endpoint
  calico              = { image_registry = try(local.infra.storage.ecr.calico_image_registry, null) }
}

data "aws_caller_identity" "global" {
  provider = aws.global
}

data "aws_caller_identity" "this" {}

locals {
  # Determine if the EKS cluster is in the same account as the hosted zone
  is_eks_account_same = data.aws_caller_identity.this.account_id == data.aws_caller_identity.global.account_id
}

moved {
  from = module.irsa_external_dns[0]
  to   = module.irsa_external_dns
}

# If you are enabling the IRSA configuration for external-dns.
# You will need to add the role created(module.irsa_external_dns.irsa_role) to
# the following annotation to the `external-dns` service account:
# `eks.amazonaws.com/role-arn: <<module.irsa_external_dns.irsa_role>>`
module "irsa_external_dns" {
  source              = "./../../../../modules/irsa"
  use_cluster_odc_idp = local.is_eks_account_same
  eks_info            = module.eks.info
  external_dns        = var.irsa_external_dns

  providers = {
    aws = aws.global
  }
}

moved {
  from = module.irsa_policies[0]
  to   = module.irsa_policies
}

module "irsa_policies" {
  source                  = "./../../../../modules/irsa"
  use_cluster_odc_idp     = true
  eks_info                = module.eks.info
  additional_irsa_configs = var.irsa_policies
}

# If you are enabling the IRSA configuration for external-deployments-operator
module "irsa_external_deployments_operator" {
  source                        = "./../../../../modules/irsa"
  use_cluster_odc_idp           = local.is_eks_account_same
  eks_info                      = module.eks.info
  external_deployments_operator = merge({ region : local.infra.region }, var.irsa_external_deployments_operator)

  providers = {
    aws = aws.global
  }
}

# Provider configuration for the account where the hosted zone is defined.
# Useful in configurations where accounts do not have a public hosted zone(i.e us-gov regions) and internet routing(public DNS)
# is instead defined in a different account. Configure the `global` aws alias accordingly,
# by specifying the profile belonging to the account pertaining to the hosted zone.
provider "aws" {
  alias = "global"
  # profile = "global"
  ignore_tags {
    keys = local.infra.ignore_tags
  }
  use_fips_endpoint = var.use_fips_endpoint
}

provider "aws" {
  region = local.infra.region
  ignore_tags {
    keys = local.infra.ignore_tags
  }
  use_fips_endpoint = var.use_fips_endpoint
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
