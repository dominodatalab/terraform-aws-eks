resource "aws_iam_role" "flyte_controlplane" {
  name = "${local.deploy_id}-flyte-controlplane"
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
            "${trimprefix(local.oidc_provider_url, "https://")}:sub" : [
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
  role       = aws_iam_role.flyte_controlplane.name
  policy_arn = aws_iam_policy.flyte_controlplane.arn
}

resource "random_id" "server" {
  keepers = {
    # Generate a new id each time there's a new deploy id (which should never occur)
    deploy_id = local.deploy_id
  }

  byte_length = 8
}

resource "aws_iam_role" "flyte_dataplane" {
  name = "${local.deploy_id}-flyte-dataplane"
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
            "${trimprefix(local.oidc_provider_url, "https://")}:aud" : "sts.amazonaws.com",
            "${trimprefix(local.oidc_provider_url, "https://")}:sub" : [
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
            "${trimprefix(local.oidc_provider_url, "https://")}:aud" : "sts.amazonaws.com",
            "${trimprefix(local.oidc_provider_url, "https://")}:sub" : [
              "system:serviceaccount:${var.platform_namespace}:${var.serviceaccount_names.flyteadmin}",
            ]
          }
        }
      },
      {
        Action = "sts:AssumeRoleWithWebIdentity"
        Effect = "Allow"
        Principal = {
          Federated = "accounts.google.com"
        }
        Condition : {
          StringEquals : {
            "accounts.google.com:oaud" : "${local.deploy_id}-flyte-gcp-${random_id.server.hex}"
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
  role       = aws_iam_role.flyte_dataplane.name
  policy_arn = aws_iam_policy.flyte_dataplane.arn
}
