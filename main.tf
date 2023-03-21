data "aws_default_tags" "this" {}

locals {
  kms_key_arn = var.kms.enabled ? try(data.aws_kms_key.key[0].arn, resource.aws_kms_key.domino[0].arn) : null
}

module "storage" {
  source       = "./submodules/storage"
  deploy_id    = var.deploy_id
  network_info = module.network.info
  kms_key_arn  = local.kms_key_arn
  storage      = var.storage
}

locals {
  node_groups = {
    for name, ng in
    merge(var.additional_node_groups, var.default_node_groups) :
    name => merge(ng, {
      gpu           = ng.gpu != null ? ng.gpu : anytrue([for itype in ng.instance_types : length(data.aws_ec2_instance_type.all[itype].gpus) > 0]),
      instance_tags = merge(data.aws_default_tags.this.tags, ng.tags)
    })
  }
}


module "network" {
  source              = "./submodules/network"
  deploy_id           = var.deploy_id
  region              = var.region
  node_groups         = local.node_groups
  network             = var.network
  flow_log_bucket_arn = { arn = module.storage.s3_buckets["monitoring"].arn }
}

locals {
  ssh_pvt_key_path = abspath(pathexpand(var.ssh_pvt_key_path))
  ssh_key = {
    path          = local.ssh_pvt_key_path
    key_pair_name = aws_key_pair.domino.key_name
  }
}

data "tls_public_key" "domino" {
  private_key_openssh = file(local.ssh_pvt_key_path)
}

resource "aws_key_pair" "domino" {
  key_name   = var.deploy_id
  public_key = trimspace(data.tls_public_key.domino.public_key_openssh)
}

module "bastion" {
  count = var.bastion != null ? 1 : 0

  source       = "./submodules/bastion"
  deploy_id    = var.deploy_id
  region       = var.region
  ssh_key      = local.ssh_key
  kms_key      = local.kms_key_arn
  k8s_version  = var.eks.k8s_version
  network_info = module.network.info
  bastion      = var.bastion
}

data "aws_ec2_instance_type" "all" {
  for_each      = toset(flatten([for ng in merge(var.additional_node_groups, var.default_node_groups) : ng.instance_types]))
  instance_type = each.value
}

module "eks" {
  source              = "./submodules/eks"
  deploy_id           = var.deploy_id
  region              = var.region
  ssh_key             = local.ssh_key
  node_groups         = local.node_groups
  node_groups_kms_key = local.kms_key_arn
  node_iam_policies   = module.storage.iam_policies
  efs_security_group  = module.storage.efs_security_group
  secrets_kms_key     = local.kms_key_arn
  network_info        = module.network.info
  eks                 = var.eks
  bastion_info        = try(module.bastion.info, null)

  depends_on = [
    module.network
  ]
}
