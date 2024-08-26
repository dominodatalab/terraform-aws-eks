module "infra" {
  source = "./../../../modules/infra/"

  deploy_id              = var.deploy_id
  additional_node_groups = var.additional_node_groups
  bastion                = var.bastion
  default_node_groups    = var.default_node_groups
  network                = var.network
  storage                = var.storage
  eks                    = var.eks
  kms                    = var.kms
  region                 = var.region
  ssh_pvt_key_path       = var.ssh_pvt_key_path
  tags                   = var.tags
  domino_cur             = var.domino_cur
  use_fips_endpoint      = var.use_fips_endpoint
}


module "eks" {
  source    = "./../../../modules/eks"
  deploy_id = module.infra.deploy_id
  region    = module.infra.region

  ssh_key             = module.infra.ssh_key
  node_iam_policies   = module.infra.node_iam_policies
  efs_security_group  = module.infra.efs_security_group
  eks                 = module.infra.eks
  network_info        = module.infra.network
  kms_info            = module.infra.kms
  bastion_info        = module.infra.bastion
  create_eks_role_arn = module.infra.create_eks_role_arn
  tags                = module.infra.tags
  privatelink = {
    enabled                  = var.enable_private_link
    monitoring_bucket        = module.infra.monitoring_bucket
    route53_hosted_zone_name = var.route53_hosted_zone_name
  }
  use_fips_endpoint = var.use_fips_endpoint
}

module "irsa_external_dns" {
  source   = "./../../../modules/irsa"
  eks_info = module.eks.info
  external_dns = {
    enabled          = var.route53_hosted_zone_name != null
    hosted_zone_name = var.route53_hosted_zone_name
  }
  use_fips_endpoint = var.use_fips_endpoint
}

data "aws_iam_policy_document" "mypod_s3" {
  statement {
    actions   = ["s3:ListAllMyBuckets"]
    effect    = "Allow"
    resources = ["*"]
  }
}

module "irsa_policies" {
  source   = "./../../../modules/irsa"
  eks_info = module.eks.info
  additional_irsa_configs = [{
    name                = "mypod-s3"
    namespace           = "domino-config"
    policy              = data.aws_iam_policy_document.mypod_s3.json
    serviceaccount_name = "mypod-s3"
  }]
  use_fips_endpoint = var.use_fips_endpoint
}

module "irsa_external_deployments_operator" {
  source   = "./../../../modules/irsa"
  eks_info = module.eks.info
  external_deployments_operator = {
    enabled              = true
    namespace            = "domino-config"
    service_account_name = "test-operator-account"
  }
  use_fips_endpoint = var.use_fips_endpoint
}

module "nodes" {
  source = "./../../../modules/nodes"
  region = module.infra.region

  ssh_key                = module.infra.ssh_key
  default_node_groups    = module.infra.default_node_groups
  additional_node_groups = module.infra.additional_node_groups
  eks_info               = module.eks.info
  network_info           = module.infra.network
  kms_info               = module.infra.kms
  tags                   = module.infra.tags
  use_fips_endpoint      = var.use_fips_endpoint
}

module "single_node" {
  count  = var.single_node != null ? 1 : 0
  source = "./../../../modules/single-node"

  region       = module.infra.region
  ssh_key      = module.infra.ssh_key
  single_node  = var.single_node
  eks_info     = module.eks.info
  network_info = module.infra.network
  kms_info     = module.infra.kms
}
