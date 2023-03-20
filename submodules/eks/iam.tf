## EKS IAM
data "aws_iam_policy_document" "eks_cluster" {
  statement {
    sid     = "EKSClusterAssumeRole"
    actions = ["sts:AssumeRole"]

    principals {
      type        = "Service"
      identifiers = ["eks.${local.dns_suffix}"]
    }
  }
}

resource "aws_iam_role" "eks_cluster" {
  name               = "${var.deploy_id}-eks"
  assume_role_policy = data.aws_iam_policy_document.eks_cluster.json
  lifecycle {
    ignore_changes = [name]
  }
}

resource "aws_iam_role_policy_attachment" "eks_cluster" {
  policy_arn = "${local.policy_arn_prefix}/AmazonEKSClusterPolicy"
  role       = aws_iam_role.eks_cluster.name
}

data "aws_iam_policy_document" "autoscaler" {
  statement {

    effect    = "Allow"
    resources = ["*"]

    actions = [
      "autoscaling:DescribeAutoScalingGroups",
      "autoscaling:DescribeLaunchConfigurations",
      "autoscaling:DescribeTags",
      "ec2:DescribeLaunchTemplateVersions",
    ]
  }

  statement {

    effect    = "Allow"
    resources = ["*"]

    actions = [
      "autoscaling:DescribeAutoScalingInstances",
      "autoscaling:SetDesiredCapacity",
      "autoscaling:TerminateInstanceInAutoScalingGroup",
    ]

    condition {
      test     = "StringEquals"
      variable = "autoscaling:ResourceTag/eks:cluster-name"
      values   = [var.deploy_id]
    }
  }
}

data "aws_iam_policy_document" "ebs_csi" {
  statement {

    effect    = "Allow"
    resources = ["*"]

    actions = [
      "ec2:DescribeAvailabilityZones",
      "ec2:DescribeInstances",
      "ec2:DescribeInstanceStatus",
      "ec2:DescribeSnapshots",
      "ec2:DescribeTags",
      "ec2:DescribeVolumes",
      "ec2:DescribeVolumesModifications",
    ]
  }

  statement {

    effect    = "Allow"
    resources = ["*"]

    actions = [
      "ec2:CreateSnapshot",
      "ec2:AttachVolume",
      "ec2:DetachVolume",
      "ec2:ModifyVolume",
    ]

    condition {
      test     = "StringLike"
      variable = "aws:ResourceTag/kubernetes.io/cluster/${var.deploy_id}"
      values   = ["owned"]
    }
  }

  statement {
    sid    = ""
    effect = "Allow"

    resources = [
      "arn:${data.aws_partition.current.partition}:ec2:*:*:volume/*",
      "arn:${data.aws_partition.current.partition}:ec2:*:*:snapshot/*",
    ]

    actions = ["ec2:CreateTags"]

    condition {
      test     = "StringEquals"
      variable = "ec2:CreateAction"

      values = [
        "CreateVolume",
        "CreateSnapshot",
      ]
    }
  }

  statement {
    sid    = ""
    effect = "Allow"

    resources = [
      "arn:${data.aws_partition.current.partition}:ec2:*:*:volume/*",
      "arn:${data.aws_partition.current.partition}:ec2:*:*:snapshot/*",
    ]

    actions = ["ec2:DeleteTags"]
  }

  statement {

    effect    = "Allow"
    resources = ["*"]
    actions   = ["ec2:CreateVolume"]

    condition {
      test     = "StringLike"
      variable = "aws:RequestTag/KubernetesCluster"
      values   = [var.deploy_id]
    }
  }

  statement {

    effect    = "Allow"
    resources = ["*"]

    actions = [
      "ec2:DeleteVolume",
      "ec2:DeleteSnapshot",
    ]

    condition {
      test     = "StringLike"
      variable = "aws:ResourceTag/KubernetesCluster"
      values   = [var.deploy_id]
    }
  }

  statement {

    effect    = "Allow"
    resources = ["*"]
    actions = [
      "kms:Decrypt",
      "kms:GenerateDataKey*",
      "kms:CreateGrant"
    ]
  }
}

data "aws_iam_policy_document" "snapshot" {
  statement {

    effect    = "Allow"
    resources = ["*"]

    actions = [
      "ec2:CreateSnapshot",
      "ec2:CreateTags",
      "ec2:DeleteSnapshot",
      "ec2:DeleteTags",
      "ec2:DescribeAvailabilityZones",
      "ec2:DescribeSnapshots",
      "ec2:DescribeTags",
    ]
  }
}

data "aws_iam_policy_document" "ssm" {
  statement {
    effect    = "Allow"
    resources = ["*"]

    actions = [
      "logs:CreateLogStream",
      "logs:PutLogEvents",
      "logs:DescribeLogGroups",
      "logs:DescribeLogStreams"
    ]
  }

  statement {
    effect    = "Allow"
    resources = ["*"]

    actions = [
      "kms:GenerateDataKey",
    ]
  }
}

data "aws_iam_policy_document" "custom_eks_node_policy" {
  source_policy_documents = [
    data.aws_iam_policy_document.autoscaler.json,
    data.aws_iam_policy_document.ebs_csi.json,
    data.aws_iam_policy_document.snapshot.json,
    data.aws_iam_policy_document.ssm.json
  ]
}

resource "aws_iam_policy" "custom_eks_node_policy" {
  name   = "${var.deploy_id}-nodes-custom"
  path   = "/"
  policy = data.aws_iam_policy_document.custom_eks_node_policy.json
}

locals {
  eks_aws_node_iam_policies = toset([
    "AmazonEKSWorkerNodePolicy",
    "AmazonEKS_CNI_Policy",
    "AmazonEC2ContainerRegistryReadOnly",
    "AmazonSSMManagedInstanceCore",
    "AmazonElasticFileSystemReadOnlyAccess",
  ])

  custom_node_policies = concat([aws_iam_policy.custom_eks_node_policy.arn], var.node_iam_policies)
}

resource "aws_iam_role_policy_attachment" "aws_eks_nodes" {
  for_each   = toset(local.eks_aws_node_iam_policies)
  policy_arn = "arn:${data.aws_partition.current.partition}:iam::aws:policy/${each.key}"
  role       = aws_iam_role.eks_nodes.name
}

resource "aws_iam_role_policy_attachment" "custom_eks_nodes" {
  count      = length(local.custom_node_policies)
  policy_arn = element(local.custom_node_policies, count.index)
  role       = aws_iam_role.eks_nodes.name
}

