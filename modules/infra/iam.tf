locals {
  create_eks_role_name = coalesce(var.eks.creation_role_name, "${var.deploy_id}-create-eks")
}

data "aws_iam_policy_document" "create_eks_role" {
  statement {
    sid = "EKSDeployerEKS"
    actions = [
      "eks:*"
    ]
    resources = [
      "arn:${data.aws_partition.current.partition}:eks:${var.region}:${local.aws_account_id}:cluster/${var.deploy_id}",
      "arn:${data.aws_partition.current.partition}:eks:${var.region}:${local.aws_account_id}:cluster/${var.deploy_id}/*"
    ]
    effect = "Allow"
  }

  statement {
    sid = "EKSDeployerKMS"
    actions = [
      "kms:CreateGrant",
      "kms:DescribeKey"
    ]
    resources = ["arn:${data.aws_partition.current.partition}:kms:${var.region}:${local.aws_account_id}:key/*"]
    effect    = "Allow"
  }

  statement {
    sid = "EKSDeployerIAM"
    actions = [
      "iam:PassRole",
      "iam:GetRole"
    ]
    resources = ["arn:${data.aws_partition.current.partition}:iam::${local.aws_account_id}:role/${var.deploy_id}-*"]
    effect    = "Allow"
  }

  statement {
    sid = "EKSDeployerIAMSvcLinkedRole"
    actions = [
      "iam:CreateServiceLinkedRole",
      "iam:AttachRolePolicy",
      "iam:PutRolePolicy"
    ]
    resources = ["arn:${data.aws_partition.current.partition}:iam::${local.aws_account_id}:role/aws-service-role/*"]
    effect    = "Allow"
  }
}

resource "aws_iam_policy" "create_eks_role" {
  name   = local.create_eks_role_name
  path   = "/"
  policy = data.aws_iam_policy_document.create_eks_role.json
}

resource "aws_iam_role" "create_eks_role" {
  name = local.create_eks_role_name
  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Sid    = ""
        Principal = {
          AWS = [
            "arn:${data.aws_partition.current.partition}:iam::${local.aws_account_id}:root"
          ]
        }
      },
    ]
  })
}

resource "aws_iam_role_policy_attachment" "create_eks_role" {
  role       = aws_iam_role.create_eks_role.name
  policy_arn = aws_iam_policy.create_eks_role.arn
}

resource "time_sleep" "create_eks_role_30_seconds" {
  create_duration = "30s"
  depends_on      = [aws_iam_role_policy_attachment.create_eks_role]
}
