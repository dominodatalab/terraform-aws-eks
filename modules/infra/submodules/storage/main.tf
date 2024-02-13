data "aws_elb_service_account" "this" {}
data "aws_partition" "current" {}

locals {
  private_subnet_ids = var.network_info.subnets.private[*].subnet_id
  kms_key_arn        = var.kms_info.enabled ? var.kms_info.key_arn : null

  bucket_names = {
    costs          = "${var.deploy_id}-costs"
    flyte_metadata = "${var.deploy_id}-flyte-metadata"
    flyte_data     = "${var.deploy_id}-flyte-data"
  }

  s3_buckets = { for k, v in {
    backups = {
      bucket_name = aws_s3_bucket.backups.bucket
      id          = aws_s3_bucket.backups.id
      policy_json = data.aws_iam_policy_document.backups.json
      arn         = aws_s3_bucket.backups.arn
    }
    blobs = {
      bucket_name = aws_s3_bucket.blobs.bucket
      id          = aws_s3_bucket.blobs.id
      policy_json = data.aws_iam_policy_document.blobs.json
      arn         = aws_s3_bucket.blobs.arn
    }
    costs = var.storage.costs_enabled ? {
      bucket_name = local.bucket_names["costs"]
      id          = try(aws_s3_bucket.costs[0].id)
      policy_json = data.aws_iam_policy_document.costs[0].json
      arn         = try(aws_s3_bucket.costs[0].arn)
    } : {}
    flyte_metadata = var.flyte.enabled ? {
      bucket_name = local.bucket_names["flyte_metadata"]
      id          = aws_s3_bucket.flyte_metadata[0].id
      policy_json = data.aws_iam_policy_document.flyte_metadata[0].json
      arn         = aws_s3_bucket.flyte_metadata[0].arn
    } : {}
    flyte_data = var.flyte.enabled ? {
      bucket_name = local.bucket_names["flyte_data"]
      id          = aws_s3_bucket.flyte_data[0].id
      policy_json = data.aws_iam_policy_document.flyte_data[0].json
      arn         = aws_s3_bucket.flyte_data[0].arn
    } : {}
    logs = {
      bucket_name = aws_s3_bucket.logs.bucket
      id          = aws_s3_bucket.logs.id
      policy_json = data.aws_iam_policy_document.logs.json
      arn         = aws_s3_bucket.logs.arn
    }
    monitoring = {
      bucket_name = aws_s3_bucket.monitoring.bucket
      id          = aws_s3_bucket.monitoring.id
      policy_json = data.aws_iam_policy_document.monitoring.json
      arn         = aws_s3_bucket.monitoring.arn
    }
    registry = {
      bucket_name = aws_s3_bucket.registry.bucket
      id          = aws_s3_bucket.registry.id
      policy_json = data.aws_iam_policy_document.registry.json
      arn         = aws_s3_bucket.registry.arn
    }
  } : k => v if contains(keys(v), "bucket_name") }

  backup_tagging = var.storage.enable_remote_backup ? {
    "backup_plan" = "cross-account"
  } : {}
}
