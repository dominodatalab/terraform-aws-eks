data "aws_iam_policy_document" "s3" {
  statement {
    effect    = "Allow"
    resources = [for b in local.s3_buckets : b.arn]

    actions = [
      "s3:ListBucket",
      "s3:GetBucketLocation",
      "s3:ListBucketMultipartUploads",
    ]
  }

  statement {
    sid    = ""
    effect = "Allow"

    resources = [for b in local.s3_buckets : "${b.arn}/*"]

    actions = [
      "s3:PutObject",
      "s3:GetObject",
      "s3:DeleteObject",
      "s3:ListMultipartUploadParts",
      "s3:AbortMultipartUpload",
    ]
  }
}

resource "aws_iam_policy" "s3" {
  name   = "${var.deploy_id}-S3"
  path   = "/"
  policy = data.aws_iam_policy_document.s3.json
}

data "aws_iam_policy_document" "ecr" {
  statement {
    effect    = "Allow"
    resources = ["*"]
    actions   = ["ecr:GetAuthorizationToken"]
  }

  statement {
    effect = "Allow"

    resources = [for k, repo in aws_ecr_repository.this : repo.arn]

    actions = [
      # Pull
      "ecr:GetDownloadUrlForLayer",
      "ecr:BatchGetImage",
      # Push
      "ecr:CompleteLayerUpload",
      "ecr:UploadLayerPart",
      "ecr:InitiateLayerUpload",
      "ecr:BatchCheckLayerAvailability",
      "ecr:PutImage"
    ]
  }

  override_policy_documents = local.supports_pull_through_cache ? [data.aws_iam_policy_document.ecr_pull_through_cache[0].json] : []
}

data "aws_iam_policy_document" "ecr_pull_through_cache" {
  count = local.supports_pull_through_cache ? 1 : 0

  statement {
    effect = "Allow"

    resources = [
      "arn:${data.aws_partition.current.partition}:ecr:${var.region}:${data.aws_caller_identity.this.account_id}:repository/${aws_ecr_pull_through_cache_rule.quay[0].ecr_repository_prefix}/*"
    ]

    actions = [
      "ecr:BatchGetImage",
      "ecr:BatchImportUpstreamImage",
      "ecr:CreateRepository",
      "ecr:GetDownloadUrlForLayer"
    ]
  }
}

resource "aws_iam_policy" "ecr" {
  name   = "${var.deploy_id}-ECR"
  path   = "/"
  policy = data.aws_iam_policy_document.ecr.json
}
