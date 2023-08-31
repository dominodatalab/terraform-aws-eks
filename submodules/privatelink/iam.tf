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

data "aws_iam_policy_document" "load_balancer_controller_policy" {
  source_policy_documents = [
    file("${path.module}/aws-load-balancer-controller_2.5.4_iam_policy.json")
  ]
}

resource "aws_iam_role" "load_balancer_controller" {
  name               = "${var.deploy_id}-load-balancer-controller"
  assume_role_policy = data.aws_iam_policy_document.load_balancer_controller.json
  lifecycle {
    ignore_changes = [name]
  }
}

resource "aws_iam_policy" "load_balancer_controller" {
  name   = "${var.deploy_id}-load-balancer-controller"
  policy = data.aws_iam_policy_document.load_balancer_controller_policy.json
}

resource "aws_iam_role_policy_attachment" "load_balancer_controller" {
  role       = aws_iam_role.load_balancer_controller.name
  policy_arn = aws_iam_policy.load_balancer_controller.arn
}