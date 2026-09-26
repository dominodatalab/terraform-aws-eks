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

# This stack only depends on `cluster` (for the EKS node security group) and `infra`
# (for network/monitoring bucket info) - it does not depend on, and is not depended on
# by, `nodes`. Run it in parallel with `nodes` (see `tf.sh all apply`) so the slow
# Global Accelerator endpoint-group propagation overlaps with node/addon provisioning
# instead of serializing before or after it.
module "load_balancers" {
  count = length(var.load_balancers) > 0 ? 1 : 0

  source         = "./../../../../modules/load-balancers"
  deploy_id      = local.infra.deploy_id
  load_balancers = var.load_balancers
  waf            = var.waf

  access_logs = {
    enabled   = var.access_logs.enabled
    s3_bucket = local.infra.monitoring_bucket
  }
  connection_logs = {
    enabled   = var.connection_logs.enabled
    s3_bucket = local.infra.monitoring_bucket
  }
  flow_logs = {
    enabled   = var.flow_logs.enabled
    s3_bucket = local.infra.monitoring_bucket
  }

  fqdn                        = "${local.infra.deploy_id}${var.route53_hosted_zone_name != null ? ".${var.route53_hosted_zone_name}" : ""}"
  hosted_zone_name            = var.route53_hosted_zone_name
  hosted_zone_private         = var.hosted_zone_private
  network_info                = local.infra.network
  eks_nodes_security_group_id = local.eks.eks_nodes_security_group_id
  use_fips_endpoint           = var.use_fips_endpoint
}

module "privatelink" {
  count = var.privatelink.enabled ? 1 : 0

  source              = "./../../../../modules/privatelink"
  deploy_id           = local.infra.deploy_id
  privatelink         = var.privatelink
  lb_arns             = module.load_balancers[0].info.lb_arns
  hosted_zone_private = var.hosted_zone_private
}

provider "aws" {
  region = local.infra.region
  default_tags {
    tags = local.infra.tags
  }
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
      version = "~> 6.0"
    }
  }
}
