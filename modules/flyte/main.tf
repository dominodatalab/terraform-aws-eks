data "aws_partition" "current" {}
data "aws_caller_identity" "aws_account" {}
data "aws_eks_cluster" "domino_cluster" {
  name = var.eks_cluster_name
}

data "aws_iam_openid_connect_provider" "domino_cluster_issuer" {
  count = var.enable_irsa ? 1 : 0
  url   = local.oidc_provider_url
}

locals {
  deploy_id         = lower(var.eks_cluster_name)
  oidc_provider_arn = var.enable_irsa ? data.aws_iam_openid_connect_provider.domino_cluster_issuer.0.arn : ""
  oidc_provider_url = try(trimprefix(data.aws_eks_cluster.domino_cluster.identity[0].oidc[0].issuer, "https://"), null)
}
