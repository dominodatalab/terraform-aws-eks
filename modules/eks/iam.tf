data "aws_iam_policy_document" "eks_cluster" {
  statement {
    sid     = "EKSClusterAssumeRoleService"
    actions = ["sts:AssumeRole", "sts:TagSession"]

    principals {
      type        = "Service"
      identifiers = ["eks.${local.dns_suffix}"]
    }
  }
  statement {
    sid     = "EKSClusterAssumeRoleUser"
    actions = ["sts:AssumeRole", "sts:TagSession"]

    principals {
      type        = "AWS"
      identifiers = ["arn:${data.aws_partition.current.partition}:iam::${local.aws_account_id}:root"]
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

locals {
  eks_aws_cluster_iam_policies = var.eks.auto_mode_enabled ? ["AmazonEKSClusterPolicy", "AmazonEKSBlockStoragePolicy", "AmazonEKSComputePolicy", "AmazonEKSLoadBalancingPolicy", "AmazonEKSNetworkingPolicy"] : ["AmazonEKSClusterPolicy"]
}
moved {
  from = aws_iam_role_policy_attachment.eks_cluster
  to   = aws_iam_role_policy_attachment.eks_cluster["AmazonEKSClusterPolicy"]
}

resource "aws_iam_role_policy_attachment" "eks_cluster" {
  for_each   = toset(local.eks_aws_cluster_iam_policies)
  policy_arn = "${local.policy_arn_prefix}/${each.key}"
  role       = aws_iam_role.eks_cluster.name
}

data "aws_iam_policy_document" "autoscaler" {
  statement {

    effect    = "Allow"
    resources = ["*"]

    actions = [
      "autoscaling:DescribeAutoScalingGroups",
      "autoscaling:DescribeLaunchConfigurations",
      "autoscaling:DescribeScalingActivities",
      "autoscaling:DescribeTags",
      "ec2:DescribeImages",
      "ec2:DescribeInstanceTypes",
      "ec2:DescribeLaunchTemplateVersions",
      "ec2:GetInstanceTypesFromInstanceRequirements",
      "eks:DescribeNodegroup"
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
    resources = ["arn:${data.aws_partition.current.partition}:logs:*:${local.aws_account_id}:log-group:${var.eks.ssm_log_group_name}:*"]
    actions = [
      "logs:CreateLogStream",
      "logs:PutLogEvents",
      "logs:DescribeLogStreams"
    ]
  }

  statement {
    effect    = "Allow"
    resources = ["*"]
    actions = [
      "logs:DescribeLogGroups"
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
  eks_aws_node_iam_policies = [
    "AmazonEKSWorkerNodePolicy",
    "AmazonEKS_CNI_Policy",
    "AmazonEC2ContainerRegistryReadOnly",
    "AmazonSSMManagedInstanceCore",
    "AmazonElasticFileSystemReadOnlyAccess",
  ]
  eks_auto_aws_node_iam_policies = ["AmazonEC2ContainerRegistryPullOnly", "AmazonEKSWorkerNodeMinimalPolicy"]

  custom_node_policies = concat([aws_iam_policy.custom_eks_node_policy.arn], var.node_iam_policies)
}


data "aws_iam_policy_document" "auto_node_trust_policy" {
  count = var.eks.auto_mode_enabled ? 1 : 0
  statement {
    effect = "Allow"
    principals {
      type        = "Service"
      identifiers = ["ec2.amazonaws.com"]
    }
    actions = ["sts:AssumeRole"]
  }
}

resource "aws_iam_role" "eks_auto_node_role" {
  count              = var.eks.auto_mode_enabled ? 1 : 0
  name               = "${var.deploy_id}-AmazonEKSAutoNodeRole"
  assume_role_policy = data.aws_iam_policy_document.auto_node_trust_policy[0].json
}

resource "aws_iam_role_policy_attachment" "aws_auto_eks_nodes" {
  for_each   = var.eks.auto_mode_enabled ? toset(local.eks_auto_aws_node_iam_policies) : toset([])
  role       = aws_iam_role.eks_auto_node_role[0].name
  policy_arn = "arn:${data.aws_partition.current.partition}:iam::aws:policy/${each.key}"
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


resource "aws_eks_identity_provider_config" "this" {
  for_each = { for idp in var.eks.identity_providers : idp.identity_provider_config_name => idp }

  cluster_name = aws_eks_cluster.this.name

  oidc {
    client_id                     = each.value.client_id
    groups_claim                  = lookup(each.value, "groups_claim", null)
    groups_prefix                 = lookup(each.value, "groups_prefix", null)
    identity_provider_config_name = each.value.identity_provider_config_name
    issuer_url                    = try(each.value.issuer_url, aws_iam_openid_connect_provider.oidc_provider.url)
    required_claims               = lookup(each.value, "required_claims", null)
    username_claim                = lookup(each.value, "username_claim", null)
    username_prefix               = lookup(each.value, "username_prefix", null)
  }
}
