resource "aws_iam_role" "external_deployments_operator" {
  count = var.external_deployments_operator.enabled ? 1 : 0

  name = local.external_deployments_operator_role
  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRoleWithWebIdentity"
        Effect = "Allow"
        Principal = {
          Federated = local.oidc_provider_arn
        }
        Condition : {
          StringEquals : {
            "${trimprefix(local.oidc_provider_url, "https://")}:aud" : "sts.amazonaws.com",
            "${trimprefix(local.oidc_provider_url, "https://")}:sub" : "system:serviceaccount:${var.external_deployments_operator.namespace}:${var.external_deployments_operator.service_account_name}"
          }
        }
      },
      {
        Action = ["sts:AssumeRole"]
        Effect = "Allow"
        Principal = {
          Service = ["sagemaker.amazonaws.com"]
          AWS     = ["arn:${data.aws_partition.current.partition}:iam::${local.account_id}:role/${local.external_deployments_operator_role}"]
        }
      },
    ]
  })
}

data "aws_iam_policy_document" "external_deployments_operator" {
  statement {
    sid       = "StsAllowAssumeRole"
    effect    = "Allow"
    actions   = ["sts:AssumeRole"]
    resources = ["*"]
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
      "ecr:UploadLayerPart",
    ]
    resources = [
      "arn:${data.aws_partition.current.partition}:ecr:${var.region}:${local.account_id}:repository/${local.external_deployments_repository}",
      "arn:${data.aws_partition.current.partition}:ecr:${var.region}:${local.account_id}:repository/${local.external_deployments_repository}*"
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
    sid       = "KmsDecryptDominoBlobs"
    effect    = "Allow"
    actions   = ["kms:Decrypt"]
    resources = [local.kms_key_arn]
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
      "arn:${data.aws_partition.current.partition}:logs:${var.region}:${local.account_id}:log-group:/aws/sagemaker/*"
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
      "arn:${data.aws_partition.current.partition}:ecr:${var.region}:${local.account_id}:repository/${local.environments_repository}",
      "arn:${data.aws_partition.current.partition}:ecr:${var.region}:${local.account_id}:repository/${local.environments_repository}*"
    ]
  }
}

resource "aws_iam_policy" "external_deployments_operator" {

  count  = var.external_deployments_operator.enabled ? 1 : 0
  name   = "${local.name_prefix}-external-deployments-operator"
  policy = data.aws_iam_policy_document.external_deployments_operator.json
}

resource "aws_iam_role_policy_attachment" "external_deployments_operator" {
  count      = var.external_deployments_operator.enabled ? 1 : 0
  role       = aws_iam_role.external_deployments_operator[0].name
  policy_arn = aws_iam_policy.external_deployments_operator[0].arn
}
