locals {
  s3_server_side_encryption = var.kms_info.enabled ? "aws:kms" : "AES256"
  kms_key_arn               = var.kms_info.enabled ? var.kms_info.key_arn : null
}

resource "aws_s3_bucket" "flyte_metadata" {
  bucket              = "${local.deploy_id}-flyte-metadata"
  force_destroy       = var.force_destroy_on_deletion
  object_lock_enabled = false
}

data "aws_iam_policy_document" "flyte_metadata" {
  statement {
    effect = "Deny"

    resources = [
      "arn:${data.aws_partition.current.partition}:s3:::${aws_s3_bucket.flyte_metadata.bucket}",
      "arn:${data.aws_partition.current.partition}:s3:::${aws_s3_bucket.flyte_metadata.bucket}/*",
    ]

    actions = ["s3:*"]

    condition {
      test     = "Bool"
      variable = "aws:SecureTransport"
      values   = ["false"]
    }

    principals {
      type        = "AWS"
      identifiers = ["*"]
    }
  }
}

resource "aws_s3_bucket_policy" "flyte_metadata" {
  bucket = aws_s3_bucket.flyte_metadata.id
  policy = data.aws_iam_policy_document.flyte_metadata.json
}

resource "aws_s3_bucket_server_side_encryption_configuration" "flye_metadata_encryption" {
  bucket = aws_s3_bucket.flyte_metadata.bucket
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

resource "aws_s3_bucket" "flyte_data" {
  bucket              = "${local.deploy_id}-flyte-data"
  force_destroy       = var.force_destroy_on_deletion
  object_lock_enabled = false
}

data "aws_iam_policy_document" "flyte_data" {
  statement {
    effect = "Deny"

    resources = [
      "arn:${data.aws_partition.current.partition}:s3:::${aws_s3_bucket.flyte_data.bucket}",
      "arn:${data.aws_partition.current.partition}:s3:::${aws_s3_bucket.flyte_data.bucket}/*",
    ]

    actions = ["s3:*"]

    condition {
      test     = "Bool"
      variable = "aws:SecureTransport"
      values   = ["false"]
    }

    principals {
      type        = "AWS"
      identifiers = ["*"]
    }
  }
}

resource "aws_s3_bucket_policy" "flyte_data" {
  bucket = aws_s3_bucket.flyte_data.id
  policy = data.aws_iam_policy_document.flyte_data.json
}

resource "aws_s3_bucket_server_side_encryption_configuration" "flyte_data_encryption" {
  bucket = aws_s3_bucket.flyte_data.bucket
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

resource "aws_s3_bucket_cors_configuration" "flyte_data" {
  bucket = aws_s3_bucket.flyte_data.id

  cors_rule {
    allowed_headers = []
    allowed_methods = ["GET"]
    allowed_origins = [var.user_host]
    max_age_seconds = 3000
  }
}
