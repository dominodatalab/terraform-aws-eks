data "aws_elb_service_account" "this" {}
data "aws_partition" "current" {}
data "aws_caller_identity" "this" {}

locals {
  private_subnet_ids = var.network_info.subnets.private[*].subnet_id
  kms_key_arn        = var.kms_info.enabled ? var.kms_info.key_arn : null
  deploy_efs         = var.storage.filesystem_type == "efs" || var.storage.netapp.migrate_from_efs.enabled
  deploy_netapp      = var.storage.filesystem_type == "netapp" || var.storage.netapp.migrate_from_efs.enabled

  s3_buckets = { for k, v in {
    monitoring = { # We need the monitoring bucket for nginx
      bucket_name               = aws_s3_bucket.monitoring.bucket
      id                        = aws_s3_bucket.monitoring.id
      policy_json               = data.aws_iam_policy_document.monitoring.json
      arn                       = aws_s3_bucket.monitoring.arn
      domain_name               = aws_s3_bucket.monitoring.bucket_domain_name
      regional_domain_name      = aws_s3_bucket.monitoring.bucket_regional_domain_name
      fips_regional_domain_name = replace(aws_s3_bucket.monitoring.bucket_regional_domain_name, ".s3.", ".s3-fips.")
    }
    backups = local.create_s3 ? {
      bucket_name               = aws_s3_bucket.backups[0].bucket
      id                        = aws_s3_bucket.backups[0].id
      policy_json               = data.aws_iam_policy_document.backups[0].json
      arn                       = aws_s3_bucket.backups[0].arn
      domain_name               = aws_s3_bucket.backups[0].bucket_domain_name
      regional_domain_name      = aws_s3_bucket.backups[0].bucket_regional_domain_name
      fips_regional_domain_name = replace(aws_s3_bucket.backups[0].bucket_regional_domain_name, ".s3.", ".s3-fips.")
    } : {}
    blobs = local.create_s3 ? {
      bucket_name               = aws_s3_bucket.blobs[0].bucket
      id                        = aws_s3_bucket.blobs[0].id
      policy_json               = data.aws_iam_policy_document.blobs[0].json
      arn                       = aws_s3_bucket.blobs[0].arn
      domain_name               = aws_s3_bucket.blobs[0].bucket_domain_name
      regional_domain_name      = aws_s3_bucket.blobs[0].bucket_regional_domain_name
      fips_regional_domain_name = replace(aws_s3_bucket.blobs[0].bucket_regional_domain_name, ".s3.", ".s3-fips.")
    } : {}
    logs = local.create_s3 ? {
      bucket_name               = aws_s3_bucket.logs[0].bucket
      id                        = aws_s3_bucket.logs[0].id
      policy_json               = data.aws_iam_policy_document.logs[0].json
      arn                       = aws_s3_bucket.logs[0].arn
      domain_name               = aws_s3_bucket.logs[0].bucket_domain_name
      regional_domain_name      = aws_s3_bucket.logs[0].bucket_regional_domain_name
      fips_regional_domain_name = replace(aws_s3_bucket.logs[0].bucket_regional_domain_name, ".s3.", ".s3-fips.")
    } : {}
    registry = local.create_s3 ? {
      bucket_name               = aws_s3_bucket.registry[0].bucket
      id                        = aws_s3_bucket.registry[0].id
      policy_json               = data.aws_iam_policy_document.registry[0].json
      arn                       = aws_s3_bucket.registry[0].arn
      domain_name               = aws_s3_bucket.registry[0].bucket_domain_name
      regional_domain_name      = aws_s3_bucket.registry[0].bucket_regional_domain_name
      fips_regional_domain_name = replace(aws_s3_bucket.registry[0].bucket_regional_domain_name, ".s3.", ".s3-fips.")
    } : {}
    costs = var.storage.costs_enabled ? {
      bucket_name               = aws_s3_bucket.costs[0].bucket
      id                        = aws_s3_bucket.costs[0].id
      policy_json               = data.aws_iam_policy_document.costs[0].json
      arn                       = aws_s3_bucket.costs[0].arn
      domain_name               = aws_s3_bucket.costs[0].bucket_domain_name
      regional_domain_name      = aws_s3_bucket.costs[0].bucket_regional_domain_name
      fips_regional_domain_name = replace(aws_s3_bucket.costs[0].bucket_regional_domain_name, ".s3.", ".s3-fips.")
    } : {}
  } : k => v if contains(keys(v), "bucket_name") }

  backup_tagging = var.storage.enable_remote_backup ? {
    "backup_plan" = "cross-account"
  } : {}
}
