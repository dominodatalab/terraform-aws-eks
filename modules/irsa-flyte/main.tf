data "aws_caller_identity" "aws_account" {}

locals {
  oidc_provider_url = var.use_cluster_odc_idp ? var.eks_info.cluster.oidc.cert.url : aws_iam_openid_connect_provider.this[0].url
  oidc_provider_arn = var.use_cluster_odc_idp ? var.eks_info.cluster.oidc.arn : aws_iam_openid_connect_provider.this[0].arn
  name_prefix       = var.eks_info.cluster.specs.name
  aws_account_id    = data.aws_caller_identity.aws_account.account_id
}
