data "aws_region" "current" {}

locals {
  policy_vars = {
    partition  = data.aws_partition.current.partition
    account_id = var.eks_info.cluster.specs.account_id
    region     = data.aws_region.current.region
    deploy_id  = local.name_prefix
  }

  oidc_issuer = try(trimprefix(local.oidc_provider_url, "https://"), null)

  configs = { for c in var.additional_irsa_configs : c.name => c }
}

resource "aws_iam_role" "this" {
  for_each = local.configs

  name = "${local.name_prefix}-${each.value.name}"
  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      # Action must stay a list on both branches of this conditional, or Terraform
      # errors with "Inconsistent conditional result types" between the two statements.
      each.value.pod_identity ? {
        Effect = "Allow"
        Principal = {
          Service = "pods.eks.amazonaws.com"
        }
        Action = ["sts:AssumeRole", "sts:TagSession"]
        Condition = {
          StringEquals = {
            "aws:SourceAccount" = local.policy_vars.account_id
          }
          ArnEquals = {
            "aws:SourceArn" = var.eks_info.cluster.arn
          }
        }
        } : {
        Effect = "Allow"
        Principal = {
          Federated = local.oidc_provider_arn
        }
        Action = ["sts:AssumeRoleWithWebIdentity"]
        Condition = {
          StringEquals = {
            "${local.oidc_issuer}:sub" = "system:serviceaccount:${each.value.namespace}:${each.value.serviceaccount_name}"
            "${local.oidc_issuer}:aud" = "sts.amazonaws.com"
          }
        }
      }
    ]
  })

  lifecycle {
    precondition {
      condition     = each.value.pod_identity || local.oidc_provider_arn != null
      error_message = "additional_irsa_configs[\"${each.key}\"] needs an OIDC provider on the cluster unless pod_identity is true"
    }
  }
}

resource "aws_iam_policy" "this" {
  for_each = local.configs
  name     = "${local.name_prefix}-${each.value.name}"
  path     = "/"
  # A ternary, not coalesce: coalesce evaluates both arguments, so an inline policy
  # with no bundled file would fail on the missing templatefile.
  policy = each.value.policy != null ? each.value.policy : templatefile("${path.module}/apps-policies/${each.key}.json.tftpl", local.policy_vars)
}

resource "aws_iam_role_policy_attachment" "this" {
  for_each   = local.configs
  role       = aws_iam_role.this[each.key].name
  policy_arn = aws_iam_policy.this[each.key].arn
}

resource "aws_eks_pod_identity_association" "this" {
  for_each = { for k, v in local.configs : k => v if v.pod_identity }

  cluster_name    = var.eks_info.cluster.specs.name
  namespace       = each.value.namespace
  service_account = each.value.serviceaccount_name
  role_arn        = aws_iam_role.this[each.key].arn

  lifecycle {
    precondition {
      condition = length([
        for c in local.configs : c
        if c.namespace == each.value.namespace && c.serviceaccount_name == each.value.serviceaccount_name
      ]) == 1
      error_message = "namespace/serviceaccount_name ${each.value.namespace}/${each.value.serviceaccount_name} is used by more than one additional_irsa_configs entry; EKS allows only one pod identity association per pair"
    }
  }
}
