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

resource "aws_iam_role_policy_attachment" "s3" {
  for_each   = toset([for r in var.roles : r.name])
  policy_arn = aws_iam_policy.s3.arn
  role       = each.value
}
