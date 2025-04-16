resource "aws_iam_role" "this" {
  for_each = { for irsa in var.additional_irsa_configs : irsa.name => irsa }

  name = "${local.name_prefix}-${each.value.name}"
  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      each.value.pod_identity ? {
        Effect = "Allow"
        Principal = {
          Service = "pods.eks.amazonaws.com"
        }
        Action = [
          "sts:AssumeRole",
          "sts:TagSession"
        ]
        Condition = {}
        } : {
        Effect = "Allow"
        Principal = {
          Federated = local.oidc_provider_arn
        }
        Action = [
          "sts:AssumeRoleWithWebIdentity"
        ]
        Condition = {
          StringEquals = {
            "${trimprefix(local.oidc_provider_url, "https://")}:sub" = "system:serviceaccount:${each.value.namespace}:${each.value.serviceaccount_name}"
            "${trimprefix(local.oidc_provider_url, "https://")}:aud" = "sts.amazonaws.com"
          }
        }
      }
    ]
  })
}

data "aws_partition" "this" {}
data "aws_caller_identity" "this" {}
locals {
  policies_vars = {
    account_id = data.aws_caller_identity.this.account_id
    partition  = data.aws_partition.this.partition
  }
}

resource "aws_iam_policy" "this" {
  for_each = { for irsa in var.additional_irsa_configs : irsa.name => irsa }
  name     = "${local.name_prefix}-${each.value.name}"
  path     = "/"
  policy   = each.value.policy != null ? each.value.policy : templatefile("${path.module}/apps-policies/${each.value.name}.json", local.policies_vars)
}

resource "aws_iam_role_policy_attachment" "this" {
  for_each   = { for irsa in var.additional_irsa_configs : irsa.name => irsa }
  role       = aws_iam_role.this[each.key].name
  policy_arn = aws_iam_policy.this[each.key].arn
}

resource "aws_eks_pod_identity_association" "this" {
  for_each = { for irsa in var.additional_irsa_configs : irsa.name => irsa if irsa.pod_identity }

  cluster_name    = var.eks_info.cluster.specs.name
  namespace       = each.value.namespace
  service_account = each.value.serviceaccount_name
  role_arn        = aws_iam_role.this[each.key].arn
}
