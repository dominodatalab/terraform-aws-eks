data "aws_partition" "current" {}

locals {
  deploy_id         = var.eks_info.cluster.specs.name
  oidc_provider_arn = var.eks_info.cluster.oidc.arn
  oidc_provider_url = var.eks_info.cluster.oidc.cert.url
}