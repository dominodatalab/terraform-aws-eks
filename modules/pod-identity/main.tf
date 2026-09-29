data "aws_partition" "current" {}

locals {
  name_prefix = var.eks_info.cluster.specs.name
  account_id  = var.eks_info.cluster.specs.account_id
  cluster_arn = "arn:${data.aws_partition.current.partition}:eks:${var.region}:${local.account_id}:cluster/${local.name_prefix}"

  configs = { for config in var.additional_pod_identity_configs : config.name => config }
}

# One document serves every config; see README.md "Scoping" for why.
data "aws_iam_policy_document" "trust" {
  statement {
    sid     = "EksPodIdentityAssumer"
    actions = ["sts:AssumeRole", "sts:TagSession"]

    principals {
      type        = "Service"
      identifiers = ["pods.eks.amazonaws.com"]
    }

    # Without both, the pod identity service will assume this role on behalf of any cluster
    # in any account that names its ARN in an association.
    condition {
      test     = "StringEquals"
      variable = "aws:SourceAccount"
      values   = [local.account_id]
    }

    condition {
      test     = "ArnEquals"
      variable = "aws:SourceArn"
      values   = [local.cluster_arn]
    }
  }
}

resource "aws_iam_role" "this" {
  for_each = local.configs

  name               = "${local.name_prefix}-${each.value.name}"
  assume_role_policy = data.aws_iam_policy_document.trust.json
}

resource "aws_iam_policy" "this" {
  for_each = local.configs

  name   = "${local.name_prefix}-${each.value.name}"
  path   = "/"
  policy = each.value.policy
}

resource "aws_iam_role_policy_attachment" "this" {
  for_each = local.configs

  role       = aws_iam_role.this[each.key].name
  policy_arn = aws_iam_policy.this[each.key].arn
}

resource "aws_eks_pod_identity_association" "this" {
  for_each = local.configs

  cluster_name    = local.name_prefix
  namespace       = each.value.namespace
  service_account = each.value.serviceaccount_name
  role_arn        = aws_iam_role.this[each.key].arn
}
