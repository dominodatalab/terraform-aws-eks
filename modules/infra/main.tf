data "aws_default_tags" "this" {}
data "aws_partition" "current" {}
data "aws_caller_identity" "aws_account" {}

locals {
  kms_key = var.kms.key_id != null ? data.aws_kms_key.key[0] : aws_kms_key.domino[0]
  kms_info = {
    key_id  = local.kms_key.id
    key_arn = local.kms_key.arn
    enabled = var.kms.enabled
  }
  deploy_cur = !strcontains(var.region, "us-gov") && var.domino_cur.provision_cost_usage_report
}


module "cost_usage_report" {
  #https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/cur_report_definition.html
  # is only available in us-east-1
  count        = local.deploy_cur ? 1 : 0
  source       = "./submodules/cost-usage-report"
  deploy_id    = var.deploy_id
  network_info = module.network.info
  kms_info     = local.kms_info
  region       = var.region
  providers = {
    aws.us-east-1 = aws.us-east-1
  }
}

module "storage" {
  source            = "./submodules/storage"
  deploy_id         = var.deploy_id
  network_info      = module.network.info
  kms_info          = local.kms_info
  storage           = var.storage
  use_fips_endpoint = var.use_fips_endpoint
  region            = var.region
}

data "aws_ec2_instance_type" "all" {
  for_each      = toset(flatten([for ng in merge(var.additional_node_groups, var.default_node_groups, var.karpenter_node_groups) : ng.instance_types]))
  instance_type = each.value
}

locals {
  node_groups = {
    for name, ng in
    merge(var.additional_node_groups, var.default_node_groups, var.karpenter_node_groups) :
    name => merge(ng, {
      gpu           = ng.gpu != null ? ng.gpu : anytrue([for itype in ng.instance_types : length(data.aws_ec2_instance_type.all[itype].gpus) > 0]),
      instance_tags = merge(data.aws_default_tags.this.tags, ng.tags)
    })
  }
  create_s3  = try(var.storage.s3.create, false)
  create_ecr = try(var.storage.ecr.create, false)
}


moved {
  from = module.eks.module.network[0]
  to   = module.eks.module.network
}

module "network" {
  source              = "./submodules/network"
  deploy_id           = var.deploy_id
  region              = var.region
  node_groups         = local.node_groups
  network             = var.network
  flow_log_bucket_arn = local.create_s3 ? { arn = module.storage.info.s3.buckets.monitoring.arn } : null
}

module "vpn" {
  count           = var.vpn_connections.create ? 1 : 0
  source          = "./submodules/vpn"
  deploy_id       = var.deploy_id
  network_info    = module.network.info
  vpn_connections = var.vpn_connections.connections
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
  count        = var.bastion.enabled ? 1 : 0
  source       = "./submodules/bastion"
  deploy_id    = var.deploy_id
  region       = var.region
  ssh_key      = local.ssh_key
  kms_info     = local.kms_info
  k8s_version  = var.eks.k8s_version
  network_info = module.network.info
  bastion      = var.bastion
}

locals {
  cost_usage_report_info = var.domino_cur.provision_cost_usage_report && length(module.cost_usage_report) > 0 ? module.cost_usage_report[0].info : null
  bastion_info           = var.bastion.enabled && length(module.bastion) > 0 ? module.bastion[0].info : null
  add_s3_pol             = [module.storage.info.s3.iam_policy_arn]
  add_ecr_pol            = local.create_ecr ? concat([module.storage.info.ecr.iam_policy_arn], local.add_s3_pol) : local.add_s3_pol
  node_iam_policies      = local.cost_usage_report_info != null ? concat(local.add_ecr_pol, [local.cost_usage_report_info.cur_iam_policy_arn]) : local.add_ecr_pol
}
