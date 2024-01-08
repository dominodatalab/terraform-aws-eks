
data "aws_caller_identity" "aws_account" {}

locals {
  # Determine whether we need to create a provider on `this` account to reference the EKS OIDC IDP connector.
  is_eks_account_same = strcontains(var.eks_info.cluster.oidc.arn, data.aws_caller_identity.aws_account.account_id)
  oidc_provider_url   = local.is_eks_account_same ? var.eks_info.cluster.oidc.cert.url : aws_iam_openid_connect_provider.this[0].url
  oidc_provider_arn   = local.is_eks_account_same ? var.eks_info.cluster.oidc.arn : aws_iam_openid_connect_provider.this[0].arn
  name_prefix         = var.eks_info.cluster.specs.name
}

resource "aws_iam_openid_connect_provider" "this" {
  count           = strcontains(var.eks_info.cluster.oidc.arn, data.aws_caller_identity.aws_account.account_id) ? 0 : 1
  url             = var.eks_info.cluster.oidc.cert.url
  client_id_list  = ["sts.amazonaws.com"]
  thumbprint_list = var.eks_info.cluster.oidc.cert.thumbprint_list
  depends_on      = [data.aws_caller_identity.aws_account]
}
