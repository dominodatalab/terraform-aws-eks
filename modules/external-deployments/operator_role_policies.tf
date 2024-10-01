data "aws_iam_policy_document" "decrypt_blobs_kms" {
  count = var.kms_info.enabled ? 1 : 0
  statement {
    sid       = "KmsDecryptDominoBlobs"
    effect    = "Allow"
    actions   = ["kms:Decrypt"]
    resources = [var.kms_info.key_arn]
  }
}

data "aws_iam_policy_document" "in_account_policies" {
  source_policy_documents = var.kms_info.enabled ? [data.aws_iam_policy_document.decrypt_blobs_kms[0].json] : []
  statement {
    sid     = "StsAllowSelfAssumeRole"
    effect  = "Allow"
    actions = ["sts:AssumeRole"]
    resources = [
      "arn:${data.aws_partition.current.partition}:iam::${local.account_id}:role/${local.operator_role}"
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
      "arn:${data.aws_partition.current.partition}:iam::${local.account_id}:role/${local.operator_role}"
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
      "arn:${data.aws_partition.current.partition}:ecr:${local.region}:${local.account_id}:repository/${local.repository}",
      "arn:${data.aws_partition.current.partition}:ecr:${local.region}:${local.account_id}:repository/${local.repository}*"
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
      "arn:${data.aws_partition.current.partition}:logs:${local.region}:${local.account_id}:log-group:/aws/sagemaker/*"
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
      "sagemaker:DeleteTags",
      "sagemaker:DescribeEndpoint",
      "sagemaker:DescribeEndpointConfig",
      "sagemaker:DescribeModel",
      "sagemaker:InvokeEndpoint",
      "sagemaker:InvokeEndpointWithResponseStream",
      "sagemaker:UpdateEndpoint",
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
      "arn:${data.aws_partition.current.partition}:ecr:${local.region}:${local.account_id}:repository/${local.environments_repository}",
      "arn:${data.aws_partition.current.partition}:ecr:${local.region}:${local.account_id}:repository/${local.environments_repository}*"
    ]
  }
  statement {
    sid    = "S3ManageUseTargetBucket"
    effect = "Allow"
    actions = [
      "s3:AbortMultipartUpload",
      "s3:CreateBucket",
      "s3:DeleteBucket",
      "s3:DeleteObject",
      "s3:DeleteObjectTagging",
      "s3:DeleteObjectVersionTagging",
      "s3:GetBucketTagging",
      "s3:GetBucketVersioning",
      "s3:GetBucketObjectLockConfiguration",
      "s3:GetObject",
      "s3:GetObjectAcl",
      "s3:GetObjectVersion",
      "s3:GetObjectVersionAcl",
      "s3:GetObjectTagging",
      "s3:GetObjectRetention",
      "s3:ListBucket",
      "s3:ListBucketVersions",
      "s3:ListBucketMultipartUploads",
      "s3:ListMultipartUploadParts",
      "s3:PutBucketObjectLockConfiguration",
      "s3:PutBucketTagging",
      "s3:PutBucketVersioning",
      "s3:PutObject",
      "s3:PutObjectAcl",
      "s3:PutObjectTagging",
      "s3:PutObjectVersionAcl",
      "s3:PutObjectVersionTagging",
      "s3:PutObjectRetention"
    ]
    resources = [
      "arn:${data.aws_partition.current.partition}:s3:::${local.bucket}",
      "arn:${data.aws_partition.current.partition}:s3:::${local.bucket}/*"
    ]
  }
}

data "aws_iam_policy_document" "assume_any_role" {
  statement {
    sid       = "StsAllowOtherAccountsAssumeRole"
    effect    = "Allow"
    actions   = ["sts:AssumeRole"]
    resources = ["*"]
    condition {
      test     = "StringNotLike"
      variable = "aws:ResourceAccount"
      values   = [local.account_id]
    }
  }
}

data "aws_iam_policy_document" "operator_grant_policy" {
  source_policy_documents = concat(
    var.external_deployments.enable_in_account_deployments ? [data.aws_iam_policy_document.in_account_policies.json] : [],
    var.external_deployments.enable_assume_any_external_role ? [data.aws_iam_policy_document.assume_any_role.json] : []
  )
}

resource "aws_iam_policy" "operator" {
  count  = local.operator_role_needs_policy ? 1 : 0
  name   = "${local.deploy_id}-external-deployments-operator"
  policy = data.aws_iam_policy_document.operator_grant_policy.json
}

resource "aws_iam_role_policy_attachment" "operator" {
  count      = local.operator_role_needs_policy ? 1 : 0
  role       = aws_iam_role.operator.name
  policy_arn = aws_iam_policy.operator[0].arn
}
