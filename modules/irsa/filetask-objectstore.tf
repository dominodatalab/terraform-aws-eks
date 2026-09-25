resource "aws_iam_policy" "filetask_objectstore" {
  count = var.filetask_objectstore.enabled ? 1 : 0

  name   = "${local.name_prefix}-filetask-objectstore"
  path   = "/"
  policy = templatefile("${path.module}/apps-policies/filetask-objectstore.json.tftpl", merge(local.policy_vars, { buckets = var.filetask_objectstore.buckets }))
}

resource "aws_iam_role" "filetask_objectstore" {
  count = var.filetask_objectstore.enabled ? 1 : 0

  name = "${local.name_prefix}-filetask-objectstore"
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
      condition     = !contains(keys(local.configs), "filetask-objectstore")
      error_message = "An additional_irsa_configs entry may not be named \"filetask-objectstore\", because it would build a role and policy with the same IAM names as this component and fail at apply."
    }
  }
}

resource "aws_iam_role_policy_attachment" "filetask_objectstore" {
  count = var.filetask_objectstore.enabled ? 1 : 0

  role       = aws_iam_role.filetask_objectstore[0].name
  policy_arn = aws_iam_policy.filetask_objectstore[0].arn
}

resource "aws_eks_pod_identity_association" "filetask_objectstore" {
  count = var.filetask_objectstore.enabled ? 1 : 0

  cluster_name    = var.eks_info.cluster.specs.name
  namespace       = var.filetask_objectstore.namespace
  service_account = var.filetask_objectstore.serviceaccount_name
  role_arn        = aws_iam_role.filetask_objectstore[0].arn

  lifecycle {
    precondition {
      condition     = length([for c in local.configs : c if c.namespace == var.filetask_objectstore.namespace && c.serviceaccount_name == var.filetask_objectstore.serviceaccount_name]) == 0
      error_message = "An additional_irsa_configs entry binds ${var.filetask_objectstore.namespace}/${var.filetask_objectstore.serviceaccount_name}: a service account carrying both bindings resolves to the IRSA role, because the SDK credential chain reaches the web identity provider before container credentials, leaving this association in place and unused."
    }
  }
}
