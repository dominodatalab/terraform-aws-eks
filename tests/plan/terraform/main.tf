module "infra" {
  source = "./../../../modules/infra/"

  deploy_id                = var.deploy_id
  additional_node_groups   = var.additional_node_groups
  bastion                  = var.bastion
  default_node_groups      = var.default_node_groups
  network                  = var.network
  storage                  = var.storage
  eks                      = var.eks
  kms                      = var.kms
  region                   = var.region
  route53_hosted_zone_name = var.route53_hosted_zone_name
  ssh_pvt_key_path         = var.ssh_pvt_key_path
  tags                     = var.tags
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
  monitoring_bucket   = module.infra.monitoring_bucket
  enable_private_link = var.enable_private_link
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
}
