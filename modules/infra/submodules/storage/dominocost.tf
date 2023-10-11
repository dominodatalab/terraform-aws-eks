resource "aws_s3_bucket" "costs" {
  count               = var.domino_cost.storage_enabled ? 1 : 0
  bucket              = "${var.deploy_id}-costs-long-term-storage"
  force_destroy       = var.storage.s3.force_destroy_on_deletion
  object_lock_enabled = false
}

data "aws_iam_policy_document" "costs" {
  statement {
    effect = "Deny"

    resources = [
      "arn:${data.aws_partition.current.partition}:s3:::${aws_s3_bucket.costs.bucket}",
      "arn:${data.aws_partition.current.partition}:s3:::${aws_s3_bucket.costs.bucket}/*",
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

  statement {
    sid       = "DenyIncorrectEncryptionHeader"
    effect    = "Deny"
    resources = ["arn:${data.aws_partition.current.partition}:s3:::${aws_s3_bucket.costs.bucket}/*"]
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

  statement {
    sid       = "DenyUnEncryptedObjectUploads"
    effect    = "Deny"
    resources = ["arn:${data.aws_partition.current.partition}:s3:::${aws_s3_bucket.costs.bucket}/*"]
    actions   = ["s3:PutObject"]

    condition {
      test     = "Null"
      variable = "s3:x-amz-server-side-encryption"
      values   = ["true"]
    }

    principals {
      type        = "AWS"
      identifiers = ["*"]
    }
  }
}
