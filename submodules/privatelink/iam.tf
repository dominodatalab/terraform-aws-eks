data "aws_iam_policy_document" "load_balancer_controller" {
  statement {
    sid     = ""
    effect  = "Allow"
    actions = ["sts:AssumeRoleWithWebIdentity"]

    condition {
      test     = "StringEquals"
      variable = "${replace(var.oidc_provider_id, "/arn:.*:oidc-provider//", "")}:sub"
      values   = ["system:serviceaccount:${var.namespace}:${var.deploy_id}-load-balancer-controller"]
    }

    condition {
      test     = "StringEquals"
      variable = "${replace(var.oidc_provider_id, "/arn:.*:oidc-provider//", "")}:aud"
      values   = ["sts.amazonaws.com"]
    }

    principals {
      type        = "Federated"
      identifiers = [var.oidc_provider_id]
    }
  }
}