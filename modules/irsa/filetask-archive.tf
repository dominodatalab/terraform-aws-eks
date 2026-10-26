locals {
  # Same trim as filetask_objectstore_buckets: the template supplies the separator.
  filetask_archive_buckets = [for b in var.filetask_archive.buckets :
    merge(b, { prefix = b.prefix == null ? null : trim(b.prefix, "/") })
  ]
}

resource "aws_iam_policy" "filetask_archive" {
  count = var.filetask_archive.enabled ? 1 : 0

  name   = "${local.name_prefix}-filetask-archive"
  path   = "/"
  policy = templatefile("${path.module}/apps-policies/filetask-archive.json.tftpl", merge(local.policy_vars, { buckets = local.filetask_archive_buckets }))
}

resource "aws_iam_role" "filetask_archive" {
  count = var.filetask_archive.enabled ? 1 : 0

  name = "${local.name_prefix}-filetask-archive"
  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
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
      }
    ]
  })

  lifecycle {
    precondition {
      condition     = var.eks_info.cluster.arn != null
      error_message = "eks_info.cluster.arn must be set to scope the trust policy to this cluster; an unguarded null renders \"aws:SourceArn\": null which scopes the trust to nothing instead of failing"
    }

    precondition {
      condition     = !contains(keys(local.configs), "filetask-archive")
      error_message = "An additional_irsa_configs entry may not be named \"filetask-archive\", because it would build a role and policy with the same IAM names as this component and fail at apply."
    }
  }
}

resource "aws_iam_role_policy_attachment" "filetask_archive" {
  count = var.filetask_archive.enabled ? 1 : 0

  role       = aws_iam_role.filetask_archive[0].name
  policy_arn = aws_iam_policy.filetask_archive[0].arn
}

resource "aws_eks_pod_identity_association" "filetask_archive" {
  count = var.filetask_archive.enabled ? 1 : 0

  cluster_name    = var.eks_info.cluster.specs.name
  namespace       = var.filetask_archive.namespace
  service_account = var.filetask_archive.serviceaccount_name
  role_arn        = aws_iam_role.filetask_archive[0].arn

  lifecycle {
    precondition {
      condition     = length([for c in local.configs : c if c.namespace == var.filetask_archive.namespace && c.serviceaccount_name == var.filetask_archive.serviceaccount_name]) == 0
      error_message = "An additional_irsa_configs entry binds ${var.filetask_archive.namespace}/${var.filetask_archive.serviceaccount_name}: a service account carrying both bindings resolves to the IRSA role, because the SDK credential chain reaches the web identity provider before container credentials, leaving this association in place and unused."
    }

    precondition {
      # EKS allows one association per service account, so the second create fails at apply; and
      # one account for both would hand archive pods the object-store grant and vice versa.
      condition     = !var.filetask_objectstore.enabled || var.filetask_objectstore.namespace != var.filetask_archive.namespace || var.filetask_objectstore.serviceaccount_name != var.filetask_archive.serviceaccount_name
      error_message = "filetask_archive and filetask_objectstore both bind ${var.filetask_archive.namespace}/${var.filetask_archive.serviceaccount_name}: each needs its own service account."
    }
  }
}
