
data "aws_iam_policy_document" "karpenter_trust_policy" {
  count = var.karpenter.enabled ? 1 : 0
  statement {
    sid     = "KarpenterAssumer"
    actions = ["sts:AssumeRole", "sts:TagSession"]
    principals {
      type        = "Service"
      identifiers = ["pods.eks.amazonaws.com"]
    }
    condition {
      test     = "StringEquals"
      variable = "aws:SourceAccount"
      values   = [local.aws_account_id]
    }
    condition {
      test     = "ArnEquals"
      variable = "aws:SourceArn"
      values   = [aws_eks_cluster.this.arn]
    }
  }
}

data "aws_iam_policy_document" "karpenter" {
  count = var.karpenter.enabled ? 1 : 0
  statement {
    actions = [
      "ssm:GetParameter"
    ]
    effect    = "Allow"
    resources = ["arn:${data.aws_partition.current.partition}:ssm:${var.region}::parameter/aws/service/*"]
    sid       = "KarpenterSSMGetParameter"
  }
  statement {
    actions = [
      "ec2:DescribeImages",
      "ec2:RunInstances",
      "ec2:DescribeSubnets",
      "ec2:DescribeSecurityGroups",
      "ec2:DescribeLaunchTemplates",
      "ec2:DescribeInstances",
      "ec2:DescribeInstanceTypes",
      "ec2:DescribeInstanceTypeOfferings",
      "ec2:DeleteLaunchTemplate",
      "ec2:CreateTags",
      "ec2:CreateLaunchTemplate",
      "ec2:CreateFleet",
      "ec2:DescribeSpotPriceHistory",
      "pricing:GetProducts"
    ]
    effect    = "Allow"
    resources = ["*"]
    sid       = "Karpenter"
  }
  statement {
    actions = ["ec2:TerminateInstances"]
    condition {
      test     = "StringLike"
      variable = "ec2:ResourceTag/karpenter.sh/nodepool"
      values   = ["*"]
    }
    sid       = "ConditionalEC2Termination"
    effect    = "Allow"
    resources = ["*"]
  }
  statement {
    effect    = "Allow"
    actions   = ["iam:PassRole"]
    resources = [aws_iam_role.eks_nodes.arn]
    sid       = "PassNodeIAMRole"
  }
  statement {
    effect    = "Allow"
    actions   = ["eks:DescribeCluster"]
    resources = ["arn:${data.aws_partition.current.partition}:eks:${var.region}:${local.aws_account_id}:cluster/${aws_eks_cluster.this.name}"]
    sid       = "EKSClusterEndpointLookup"
  }
  statement {
    sid       = "AllowScopedInstanceProfileCreationActions"
    effect    = "Allow"
    resources = ["*"]
    actions = [
      "iam:CreateInstanceProfile"
    ]
    condition {
      test     = "StringEquals"
      variable = "aws:RequestTag/kubernetes.io/cluster/${aws_eks_cluster.this.name}"
      values   = ["owned"]
    }
    condition {
      test     = "StringEquals"
      variable = "aws:RequestTag/topology.kubernetes.io/region"
      values   = [var.region]
    }
    condition {
      test     = "StringLike"
      variable = "aws:RequestTag/karpenter.k8s.aws/ec2nodeclass"
      values   = ["*"]
    }
  }
  statement {
    sid       = "AllowScopedInstanceProfileTagActions"
    effect    = "Allow"
    resources = ["*"]
    actions = [
      "iam:TagInstanceProfile"
    ]

    condition {
      test     = "StringEquals"
      variable = "aws:ResourceTag/kubernetes.io/cluster/${aws_eks_cluster.this.name}"
      values   = ["owned"]
    }
    condition {
      test     = "StringEquals"
      variable = "aws:ResourceTag/topology.kubernetes.io/region"
      values   = [var.region]
    }
    condition {
      test     = "StringEquals"
      variable = "aws:RequestTag/kubernetes.io/cluster/${aws_eks_cluster.this.name}"
      values   = ["owned"]
    }
    condition {
      test     = "StringEquals"
      variable = "aws:RequestTag/topology.kubernetes.io/region"
      values   = [var.region]
    }
    condition {
      test     = "StringLike"
      variable = "aws:ResourceTag/karpenter.k8s.aws/ec2nodeclass"
      values   = ["*"]
    }
    condition {
      test     = "StringLike"
      variable = "aws:RequestTag/karpenter.k8s.aws/ec2nodeclass"
      values   = ["*"]
    }
  }
  statement {
    sid       = "AllowScopedInstanceProfileActions"
    effect    = "Allow"
    resources = ["*"]
    actions = [
      "iam:AddRoleToInstanceProfile",
      "iam:RemoveRoleFromInstanceProfile",
      "iam:DeleteInstanceProfile"
    ]

    condition {
      test     = "StringEquals"
      variable = "aws:ResourceTag/kubernetes.io/cluster/${aws_eks_cluster.this.name}"
      values   = ["owned"]
    }
    condition {
      test     = "StringEquals"
      variable = "aws:ResourceTag/topology.kubernetes.io/region"
      values   = [var.region]
    }
    condition {
      test     = "StringLike"
      variable = "aws:ResourceTag/karpenter.k8s.aws/ec2nodeclass"
      values   = ["*"]
    }

  }
  statement {
    sid       = "AllowInstanceProfileReadActions"
    effect    = "Allow"
    resources = ["*"]
    actions   = ["iam:GetInstanceProfile"]
  }
}

resource "aws_iam_policy" "karpenter_policy" {
  count  = var.karpenter.enabled ? 1 : 0
  name   = "${var.deploy_id}-karpenter"
  path   = "/"
  policy = data.aws_iam_policy_document.karpenter[0].json
}

resource "aws_iam_role" "karpenter" {
  count              = var.karpenter.enabled ? 1 : 0
  name               = "${var.deploy_id}-karpenter"
  assume_role_policy = data.aws_iam_policy_document.karpenter_trust_policy[0].json
}

resource "aws_iam_role_policy_attachment" "karpenter" {
  count      = var.karpenter.enabled ? 1 : 0
  policy_arn = aws_iam_policy.karpenter_policy[0].arn
  role       = aws_iam_role.karpenter[0].name
}

resource "aws_eks_pod_identity_association" "karpenter" {
  count           = var.karpenter.enabled ? 1 : 0
  cluster_name    = aws_eks_cluster.this.name
  namespace       = var.karpenter.namespace
  service_account = "karpenter"
  role_arn        = aws_iam_role.karpenter[0].arn
}
