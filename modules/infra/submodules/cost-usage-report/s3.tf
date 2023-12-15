resource "aws_s3_bucket" "athena_result" {
  bucket        = local.athena_cur_result_bucket_name
  force_destroy = true
  tags          = var.tags
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
  bucket        = local.cur_report_bucket
  force_destroy = true
  tags          = var.tags
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

resource "aws_s3_bucket_server_side_encryption_configuration" "buckets_encryption" {
  for_each = { for k, v in local.s3_buckets : k => v }

  bucket = each.value.bucket_name
  rule {
    apply_server_side_encryption_by_default {
      sse_algorithm     = local.s3_server_side_encryption
      kms_master_key_id = local.kms_key_arn
    }
    bucket_key_enabled = false
  }

  lifecycle {
    ignore_changes = [
      rule,
    ]
  }
}
