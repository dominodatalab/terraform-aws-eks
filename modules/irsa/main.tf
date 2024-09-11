data "aws_caller_identity" "aws_account" {}
data "aws_partition" "current" {}

locals {
  oidc_provider_url = var.use_cluster_odc_idp ? var.eks_info.cluster.oidc.cert.url : aws_iam_openid_connect_provider.this[0].url
  oidc_provider_arn = var.use_cluster_odc_idp ? var.eks_info.cluster.oidc.arn : aws_iam_openid_connect_provider.this[0].arn
  name_prefix       = var.eks_info.cluster.specs.name
  account_id        = var.eks_info.cluster.specs.account_id
}

resource "aws_iam_openid_connect_provider" "this" {
  count           = var.use_cluster_odc_idp ? 0 : 1
  url             = var.eks_info.cluster.oidc.cert.url
  client_id_list  = ["sts.amazonaws.com"]
  thumbprint_list = var.eks_info.cluster.oidc.cert.thumbprint_list
}
