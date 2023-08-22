locals {
  iam_policy_paths = length(var.iam_policy_paths) == 0 ? ["${path.module}/bootstrap-0.json", "${path.module}/bootstrap-1.json"] : var.iam_policy_paths
}

data "aws_caller_identity" "admin" {}
data "aws_partition" "current" {}

resource "aws_iam_policy" "deployment" {
  count = length(local.iam_policy_paths)

  name = "${var.deploy_id}-deployment-policy-${count.index}"

  policy = templatefile(
    abspath(pathexpand(local.iam_policy_paths[count.index])),
    merge(
      {
        account_id = data.aws_caller_identity.admin.account_id,
        deploy_id  = var.deploy_id,
        region     = var.region,
        partition  = data.aws_partition.current.partition
      },
      var.template_config
    )
  )
}

resource "aws_iam_role" "deployment" {
  name = "${var.deploy_id}-deployment-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Sid    = ""
        Principal = {
          AWS = "arn:${data.aws_partition.current.partition}:iam::${data.aws_caller_identity.admin.account_id}:root"
        }
      },
    ]
  })

  managed_policy_arns = aws_iam_policy.deployment[*].arn

  max_session_duration = var.max_session_duration
}
