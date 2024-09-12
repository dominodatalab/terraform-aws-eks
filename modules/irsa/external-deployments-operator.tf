locals {
  account_id                                      = var.eks_info.cluster.specs.account_id
  blobs_s3_bucket_arn                             = "arn:${data.aws_partition.current.partition}:s3:::${local.name_prefix}-blobs"
  environments_repository                         = "${local.name_prefix}/environment"
  external_deployments_repository                 = "${local.name_prefix}/${var.external_deployments_operator.repository_suffix}"
  external_deployments_bucket                     = "${local.name_prefix}-${var.external_deployments_operator.bucket_suffix}"
  external_deployments_operator_role              = "${local.name_prefix}-${var.external_deployments_operator.role_suffix}"
  external_deployments_operator_role_needs_policy = var.external_deployments_operator.enabled && (var.external_deployments_operator.grant_in_account_policies || var.external_deployments_operator.grant_assume_any_role)
}

data "aws_iam_policy_document" "external_deployments_service_account_assume_role" {
  statement {
    sid     = "ServiceAccountAssumeRole"
    actions = ["sts:AssumeRoleWithWebIdentity"]
    effect  = "Allow"
    principals {
      type        = "Federated"
      identifiers = [local.oidc_provider_arn]
    }
    condition {
      test     = "StringEquals"
      variable = "${trimprefix(local.oidc_provider_url, "https://")}:aud"
      values   = ["sts.amazonaws.com"]
    }
    condition {
      test     = "StringEquals"
      variable = "${trimprefix(local.oidc_provider_url, "https://")}:sub"
      values = [
        "system:serviceaccount:${var.external_deployments_operator.namespace}:${var.external_deployments_operator.service_account_name}"
      ]
    }
  }
}
data "aws_iam_policy_document" "external_deployments_self_sagemaker_assume_role" {
  statement {
    sid     = "SelfAssumeRole"
    actions = ["sts:AssumeRole"]
    effect  = "Allow"
    principals {
      type = "AWS"
      identifiers = [
        "arn:${data.aws_partition.current.partition}:iam::${local.account_id}:root"
      ]
    }
    condition {
      test     = "ArnLike"
      variable = "aws:PrincipalArn"
      values = [
        "arn:${data.aws_partition.current.partition}:iam::${local.account_id}:role/${local.external_deployments_operator_role}"
      ]
    }
  }
  statement {
    sid     = "SagemakerAssumeRole"
    actions = ["sts:AssumeRole"]
    effect  = "Allow"
    principals {
      type        = "Service"
      identifiers = ["sagemaker.amazonaws.com"]
    }
  }
}

data "aws_iam_policy_document" "external_deployments_operator_assume_role_policy" {
  source_policy_documents = var.external_deployments_operator.grant_in_account_policies ? [data.aws_iam_policy_document.external_deployments_service_account_assume_role.json, data.aws_iam_policy_document.external_deployments_self_sagemaker_assume_role.json] : [data.aws_iam_policy_document.external_deployments_service_account_assume_role.json]
}

resource "aws_iam_role" "external_deployments_operator" {
  count              = var.external_deployments_operator.enabled ? 1 : 0
  name               = local.external_deployments_operator_role
  assume_role_policy = data.aws_iam_policy_document.external_deployments_operator_assume_role_policy.json
}

data "aws_iam_policy_document" "external_deployments_decrypt_blobs_kms" {
  statement {
    sid       = "KmsDecryptDominoBlobs"
    effect    = "Allow"
    actions   = ["kms:Decrypt"]
    resources = [coalesce(var.external_deployments_operator.kms_key_arn, "ignored")]
  }
}

data "aws_iam_policy_document" "external_deployments_in_account_policies" {
  source_policy_documents = var.external_deployments_operator.kms_key_arn != null ? [data.aws_iam_policy_document.external_deployments_decrypt_blobs_kms.json] : []
  statement {
    sid     = "StsAllowAssumeRole"
    effect  = "Allow"
    actions = ["sts:AssumeRole"]
    resources = [
      "arn:${data.aws_partition.current.partition}:iam::${local.account_id}:role/${local.external_deployments_operator_role}"
    ]
  }
  statement {
    sid    = "IamAllowPassRole"
    effect = "Allow"
    actions = [
      "iam:GetRole",
      "iam:PassRole",
    ]
    resources = [
      "arn:${data.aws_partition.current.partition}:iam::${local.account_id}:role/${local.external_deployments_operator_role}"
    ]
  }
  statement {
    sid    = "EcrRegistrySpecificSagemakerEnvironments"
    effect = "Allow"
    actions = [
      "ecr:BatchCheckLayerAvailability",
      "ecr:BatchDeleteImage",
      "ecr:BatchGetImage",
      "ecr:CreateRepository",
      "ecr:CompleteLayerUpload",
      "ecr:DescribeImages",
      "ecr:DescribeRepositories",
      "ecr:GetDownloadUrlForLayer",
      "ecr:InitiateLayerUpload",
      "ecr:PutImage",
      "ecr:TagResource",
      "ecr:UploadLayerPart",
    ]
    resources = [
      "arn:${data.aws_partition.current.partition}:ecr:${var.external_deployments_operator.region}:${local.account_id}:repository/${local.external_deployments_repository}",
      "arn:${data.aws_partition.current.partition}:ecr:${var.external_deployments_operator.region}:${local.account_id}:repository/${local.external_deployments_repository}*"
    ]
  }
  statement {
    sid    = "EcrGlobalSagemakerEnvironments"
    effect = "Allow"
    actions = [
      "ecr:GetAuthorizationToken",
      "ecr:DescribeRegistry"
    ]
    resources = ["*"]
  }
  statement {
    sid    = "S3AccessDominoBlobs"
    effect = "Allow"
    actions = [
      "s3:GetObject",
      "s3:ListBucket"
    ]
    resources = [
      local.blobs_s3_bucket_arn,
      "${local.blobs_s3_bucket_arn}/*"
    ]
  }
  statement {
    sid       = "MetricsForSagemaker"
    effect    = "Allow"
    actions   = ["cloudwatch:PutMetricData"]
    resources = ["*"]
  }
  statement {
    sid    = "LogsForSagemaker"
    effect = "Allow"
    actions = [
      "logs:CreateLogGroup",
      "logs:CreateLogStream",
      "logs:PutLogEvents",
      "logs:DescribeLogStreams",
      "logs:GetLogEvents",
      "logs:FilterLogEvents"
    ]
    resources = [
      "arn:${data.aws_partition.current.partition}:logs:${var.external_deployments_operator.region}:${local.account_id}:log-group:/aws/sagemaker/*"
    ]
  }
  statement {
    sid    = "SagemakerManageResources"
    effect = "Allow"
    actions = [
      "sagemaker:AddTags",
      "sagemaker:CreateEndpoint",
      "sagemaker:CreateEndpointConfig",
      "sagemaker:CreateModel",
      "sagemaker:DeleteEndpoint",
      "sagemaker:DeleteEndpointConfig",
      "sagemaker:DeleteModel",
      "sagemaker:DescribeEndpoint",
      "sagemaker:DescribeEndpointConfig",
      "sagemaker:DescribeModel",
      "sagemaker:InvokeEndpoint",
      "sagemaker:UpdateEndpointWeightsAndCapacities"
    ]
    resources = ["*"]
  }
  statement {
    sid    = "AutoscalingForSagemaker"
    effect = "Allow"
    actions = [
      "application-autoscaling:DeleteScalingPolicy",
      "application-autoscaling:DeregisterScalableTarget",
      "application-autoscaling:DescribeScalableTargets",
      "application-autoscaling:DescribeScalingActivities",
      "application-autoscaling:DescribeScalingPolicies",
      "application-autoscaling:PutScalingPolicy",
      "application-autoscaling:RegisterScalableTarget",
      "application-autoscaling:TagResource"
    ]
    resources = ["*"]
  }
  statement {
    sid    = "CloudwatchForAutoscaling"
    effect = "Allow"
    actions = [
      "cloudwatch:PutMetricAlarm",
      "cloudwatch:DeleteAlarms",
      "cloudwatch:DescribeAlarms"
    ]
    resources = [
      "*"
    ]
  }
  statement {
    sid    = "IamAllowCreateServiceLinkedRole"
    effect = "Allow"
    actions = [
      "iam:CreateServiceLinkedRole"
    ]
    resources = [
      "arn:${data.aws_partition.current.partition}:iam::${local.account_id}:role/aws-service-role/sagemaker.application-autoscaling.amazonaws.com/*"
    ]
    condition {
      test     = "StringLike"
      variable = "iam:AWSServiceName"
      values = [
        "sagemaker.application-autoscaling.amazonaws.com"
      ]
    }
  }
  statement {
    sid    = "EcrRegistryReadDominoEnvironments"
    effect = "Allow"
    actions = [
      "ecr:BatchCheckLayerAvailability",
      "ecr:BatchGetImage",
      "ecr:GetDownloadUrlForLayer",
    ]
    resources = [
      "arn:${data.aws_partition.current.partition}:ecr:${var.external_deployments_operator.region}:${local.account_id}:repository/${local.environments_repository}",
      "arn:${data.aws_partition.current.partition}:ecr:${var.external_deployments_operator.region}:${local.account_id}:repository/${local.environments_repository}*"
    ]
  }
}

data "aws_iam_policy_document" "external_deployments_assume_any_role" {
  statement {
    sid       = "StsAllowAssumeRole"
    effect    = "Allow"
    actions   = ["sts:AssumeRole"]
    resources = ["*"]
  }
}

data "aws_iam_policy_document" "external_deployments_operator_grant_policy" {
  source_policy_documents   = var.external_deployments_operator.grant_in_account_policies ? [data.aws_iam_policy_document.external_deployments_in_account_policies.json] : []
  override_policy_documents = var.external_deployments_operator.grant_assume_any_role ? [data.aws_iam_policy_document.external_deployments_assume_any_role.json] : []
}

resource "aws_iam_policy" "external_deployments_operator" {
  count  = local.external_deployments_operator_role_needs_policy ? 1 : 0
  name   = "${local.name_prefix}-external-deployments-operator"
  policy = data.aws_iam_policy_document.external_deployments_operator_grant_policy.json
}

resource "aws_iam_role_policy_attachment" "external_deployments_operator" {
  count      = local.external_deployments_operator_role_needs_policy ? 1 : 0
  role       = aws_iam_role.external_deployments_operator[0].name
  policy_arn = aws_iam_policy.external_deployments_operator[0].arn
}
