
resource "aws_s3_bucket" "athena_result" {
  bucket = var.athena_cur_result_bucket_name

  tags = var.tags
}

resource "aws_s3_bucket_public_access_block" "athena_result" {
  bucket = aws_s3_bucket.athena_result.id

  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}

data "aws_iam_policy_document" "athena_result" {

  statement {
    sid       = "DenyIncorrectEncryptionHeader"
    effect    = "Deny"
    resources = ["arn:${data.aws_partition.current.partition}:s3:::${aws_s3_bucket.athena_result.bucket}/*"]
    actions   = ["s3:PutObject"]

    condition {
      test     = "StringNotEquals"
      variable = "s3:x-amz-server-side-encryption"
      values   = [local.s3_server_side_encryption]
    }

    principals {
      type        = "AWS"
      identifiers = ["*"]
    }
  }
}

resource "aws_s3_bucket_policy" "athena_result" {

  bucket = aws_s3_bucket.athena_result.id
  policy = data.aws_iam_policy_document.athena_result.json

  depends_on = [
    aws_s3_bucket_public_access_block.athena_result
  ]
}


resource "aws_s3_bucket" "cur_report" {
  bucket = var.cur_report_bucket_name

  tags = var.tags
}

resource "aws_s3_bucket_public_access_block" "cur_report" {
  bucket = aws_s3_bucket.cur_report.id

  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}

data "aws_iam_policy_document" "cur_report" {

  statement {
    principals {
      type = "Service"
      identifiers = [
        "billingreports.amazonaws.com"
      ]
    }

    actions = [
      "s3:GetBucketAcl",
      "s3:GetBucketPolicy",
    ]

    resources = [
      aws_s3_bucket.cur_report.arn
    ]
  }

  statement {
    principals {
      type = "Service"
      identifiers = [
        "billingreports.amazonaws.com"
      ]
    }

    actions = [
      "s3:PutObject"
    ]

    resources = [
      "${aws_s3_bucket.cur_report.arn}/*"
    ]
  }
}

resource "aws_s3_bucket_policy" "cur_report" {

  bucket = aws_s3_bucket.cur_report.id
  policy = data.aws_iam_policy_document.cur_report.json

  depends_on = [
    aws_s3_bucket_public_access_block.cur_report
  ]
}
