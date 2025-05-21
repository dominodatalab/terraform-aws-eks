data "aws_caller_identity" "aws_account" {}
data "aws_partition" "current" {}

locals {
  oidc_provider_url = var.eks_info.cluster.oidc.cert.url
  oidc_provider_arn = var.eks_info.cluster.oidc.arn
  name_prefix       = var.eks_info.cluster.specs.name


  external_dns_oidc_provider_url = var.external_dns.use_cluster_oidc_idp ? local.oidc_provider_url : aws_iam_openid_connect_provider.this[0].url
  external_dns_oidc_provider_arn = var.external_dns.use_cluster_oidc_idp ? local.oidc_provider_arn : aws_iam_openid_connect_provider.this[0].arn
}

resource "aws_iam_openid_connect_provider" "this" {
  count           = var.external_dns.use_cluster_oidc_idp ? 0 : 1
  provider        = aws.global
  url             = var.eks_info.cluster.oidc.cert.url
  client_id_list  = ["sts.amazonaws.com"]
  thumbprint_list = var.eks_info.cluster.oidc.cert.thumbprint_list
}
