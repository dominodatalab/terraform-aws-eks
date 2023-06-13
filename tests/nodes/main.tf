data "terraform_remote_state" "infra" {
  backend = "local"

  config = {
    path = "${path.module}/../infra/terraform.tfstate"
  }
}

data "terraform_remote_state" "eks" {
  backend = "local"

  config = {
    path = "${path.module}/../cluster/terraform.tfstate"
  }
}



locals {
  infra                  = data.terraform_remote_state.infra.outputs.infra
  eks                    = data.terraform_remote_state.eks.outputs.eks
  default_node_groups    = var.default_node_groups != null ? merge(local.infra.default_node_groups, var.default_node_groups) : local.infra.default_node_groups
  additional_node_groups = var.additional_node_groups != null ? merge(local.infra.additional_node_groups, var.additional_node_groups) : local.infra.additional_node_groups

}

module "nodes" {
  source = "./../../submodules/nodes"
  region = local.infra.region

  ssh_key                = local.infra.ssh_key
  default_node_groups    = local.default_node_groups
  additional_node_groups = local.additional_node_groups
  eks_info               = local.eks
  network_info           = local.infra.network
  kms_info               = local.infra.kms
  tags                   = local.infra.tags
}

terraform {
  required_version = ">= 1.4.0"
}
