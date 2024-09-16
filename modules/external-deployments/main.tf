data "aws_partition" "current" {}

locals {
  deploy_id                  = var.eks_info.cluster.specs.name
  oidc_provider_arn          = var.eks_info.cluster.oidc.arn
  oidc_provider_url          = var.eks_info.cluster.oidc.cert.url
  account_id                 = var.eks_info.cluster.specs.account_id
  blobs_s3_bucket_arn        = "arn:${data.aws_partition.current.partition}:s3:::${local.deploy_id}-blobs"
  environments_repository    = "${local.deploy_id}/environment"
  repository                 = "${local.deploy_id}/${var.repository_suffix}"
  bucket                     = "${local.deploy_id}-${var.bucket_suffix}"
  operator_role              = "${local.deploy_id}-${var.operator_role_suffix}"
  operator_role_needs_policy = var.enable_in_account_deployments || var.enable_assume_any_external_role
  region                     = var.region
}
