data "aws_partition" "current" {}

locals {
  aws_account_id    = var.eks_info.cluster.specs.account_id
  deploy_id         = var.eks_info.cluster.specs.name
  oidc_provider_arn = var.eks_info.cluster.oidc.arn
  oidc_provider_url = var.eks_info.cluster.oidc.cert.url
}