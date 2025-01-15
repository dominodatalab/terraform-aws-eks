resource "aws_iam_role" "flyte_controlplane" {
  count = var.enable_irsa == true ? 1 : 0
  name  = "${local.deploy_id}-flyte-controlplane"
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
            "${local.oidc_provider_url}:aud" : "sts.amazonaws.com",
            "${local.oidc_provider_url}:sub" : [
              "system:serviceaccount:${var.platform_namespace}:${var.serviceaccount_names.datacatalog}",
              "system:serviceaccount:${var.platform_namespace}:${var.serviceaccount_names.flytepropeller}",
            ]
          }
        }
      },
    ]
  })
}

data "aws_iam_policy_document" "flyte_controlplane" {
  statement {
    effect = "Allow"
    resources = [
      "arn:${data.aws_partition.current.partition}:s3:::${aws_s3_bucket.flyte_metadata.bucket}/*",
      "arn:${data.aws_partition.current.partition}:s3:::${aws_s3_bucket.flyte_metadata.bucket}"
    ]
    actions = [
      "s3:PutObject",
      "s3:GetObject",
      "s3:ListBucket",
    ]
  }
  statement {
    effect    = "Allow"
    resources = ["arn:${data.aws_partition.current.partition}:kms:${var.region}:${data.aws_caller_identity.aws_account.account_id}:key/*"]
    actions = [
      "kms:GenerateDataKey",
      "kms:Decrypt",
    ]
  }
}

resource "aws_iam_policy" "flyte_controlplane" {
  name   = "${local.deploy_id}-flyte-controlplane"
  policy = data.aws_iam_policy_document.flyte_controlplane.json
}


resource "aws_iam_role_policy_attachment" "flyte_controlplane" {
  count      = var.enable_irsa == true ? 1 : 0
  role       = aws_iam_role.flyte_controlplane.0.name
  policy_arn = aws_iam_policy.flyte_controlplane.arn
}

resource "aws_iam_role" "flyte_dataplane" {
  count = var.enable_irsa == true ? 1 : 0
  name  = "${local.deploy_id}-flyte-dataplane"
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
          StringLike : {
            "${local.oidc_provider_url}:aud" : "sts.amazonaws.com",
            "${local.oidc_provider_url}:sub" : [
              "system:serviceaccount:${var.compute_namespace}:run-*"
            ]
          }
        }
      },
      {
        Action = "sts:AssumeRoleWithWebIdentity"
        Effect = "Allow"
        Principal = {
          Federated = local.oidc_provider_arn
        }
        Condition : {
          StringEquals : {
            "${local.oidc_provider_url}:aud" : "sts.amazonaws.com",
            "${local.oidc_provider_url}:sub" : [
              "system:serviceaccount:${var.platform_namespace}:${var.serviceaccount_names.flyteadmin}",
            ]
          }
        }
      },
    ]
  })
}

data "aws_iam_policy_document" "flyte_dataplane" {
  statement {
    effect = "Allow"
    resources = [
      "arn:${data.aws_partition.current.partition}:s3:::${aws_s3_bucket.flyte_metadata.bucket}/*",
      "arn:${data.aws_partition.current.partition}:s3:::${aws_s3_bucket.flyte_metadata.bucket}",
      "arn:${data.aws_partition.current.partition}:s3:::${aws_s3_bucket.flyte_data.bucket}/*",
      "arn:${data.aws_partition.current.partition}:s3:::${aws_s3_bucket.flyte_data.bucket}",
    ]

    actions = [
      "s3:PutObject",
      "s3:GetObject",
      "s3:ListBucket"
    ]
  }
  statement {
    effect    = "Allow"
    resources = ["arn:${data.aws_partition.current.partition}:kms:${var.region}:${data.aws_caller_identity.aws_account.account_id}:key/*"]
    actions = [
      "kms:GenerateDataKey",
      "kms:Decrypt",
    ]
  }
}

resource "aws_iam_policy" "flyte_dataplane" {
  name   = "${local.deploy_id}-flyte-dataplane"
  policy = data.aws_iam_policy_document.flyte_dataplane.json
}

resource "aws_iam_role_policy_attachment" "flyte_dataplane" {
  count      = var.enable_irsa == true ? 1 : 0
  role       = aws_iam_role.flyte_dataplane.0.name
  policy_arn = aws_iam_policy.flyte_dataplane.arn
}


data "aws_iam_policy_document" "flyte_combined_policy" {
  source_policy_documents = [
    data.aws_iam_policy_document.flyte_controlplane.json,
    data.aws_iam_policy_document.flyte_dataplane.json
  ]
}

resource "aws_iam_policy" "flyte_combined" {
  name   = "${local.deploy_id}-flyte-combined"
  policy = data.aws_iam_policy_document.flyte_combined_policy.json
}

resource "aws_iam_role_policy_attachment" "flyte_node_role_attachment" {
  count      = var.enable_irsa == true ? 0 : 1
  role       = var.target_iam_role_name
  policy_arn = aws_iam_policy.flyte_combined.arn
}
