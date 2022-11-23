data "aws_ami" "eks_node" {
  provider    = aws.local
  most_recent = true
  owners      = ["amazon"]

  filter {
    name   = "name"
    values = ["amazon-eks-node-${var.k8s_version}-*"]
  }
}

module "domino_eks" {
  source                       = "./.."
  deploy_id                    = var.deploy_id
  region                       = var.region
  number_of_azs                = 2
  k8s_version                  = var.k8s_version
  route53_hosted_zone_name     = "deploys-delta.domino.tech"
  eks_master_role_names        = ["okta-poweruser", "okta-fulladmin"]
  s3_force_destroy_on_deletion = true
  bastion                      = {}
  ssh_pvt_key_path             = "domino.pem"
  tags                         = var.tags
  default_node_groups = {
    compute = {
      spot = true
      ami  = data.aws_ami.eks_node.image_id
    }
    platform = {}
    gpu      = {}
  }
}
