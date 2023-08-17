data "aws_ami" "eks_node" {
  filter {
    name   = "name"
    values = ["amazon-eks-node-${var.eks.k8s_version}-*"]
  }

  most_recent = true
  owners      = ["amazon"]
}

locals {
  default_node_groups = merge(var.default_node_groups, {
    compute = merge(var.default_node_groups.compute, {
      ami = data.aws_ami.eks_node.image_id
    })
  })
}

module "infra" {
  source = "./../../../modules/infra/"

  deploy_id              = var.deploy_id
  additional_node_groups = var.additional_node_groups
  bastion                = var.bastion
  default_node_groups    = local.default_node_groups

  eks                      = var.eks
  kms                      = var.kms
  region                   = var.region
  route53_hosted_zone_name = var.route53_hosted_zone_name
  ssh_pvt_key_path         = var.ssh_pvt_key_path
  tags                     = var.tags
}


provider "aws" {
  region = var.region
}

terraform {
  required_version = ">= 1.4.0"
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }
}
