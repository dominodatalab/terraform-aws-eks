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

module "single_node" {
  source = "./../../../modules/single-node"
  region = local.infra.region

  ssh_key      = local.infra.ssh_key
  single_node  = var.single_node
  eks_info     = local.eks
  network_info = local.infra.network
  kms_info     = local.infra.kms
}
