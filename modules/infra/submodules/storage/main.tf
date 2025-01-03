data "aws_elb_service_account" "this" {}
data "aws_partition" "current" {}
data "aws_caller_identity" "this" {}

locals {
  private_subnet_ids = var.network_info.subnets.private[*].subnet_id
  kms_key_arn        = var.kms_info.enabled ? var.kms_info.key_arn : null
  deploy_efs         = var.storage.filesystem_type == "efs" || var.storage.netapp.migrate_from_efs.enabled
  deploy_netapp      = var.storage.filesystem_type == "netapp" || var.storage.netapp.migrate_from_efs.enabled

  s3_buckets = { for k, v in {
    backups = {
      bucket_name               = aws_s3_bucket.backups.bucket
      id                        = aws_s3_bucket.backups.id
      policy_json               = data.aws_iam_policy_document.backups.json
      arn                       = aws_s3_bucket.backups.arn
      domain_name               = aws_s3_bucket.backups.bucket_domain_name
      regional_domain_name      = aws_s3_bucket.backups.bucket_regional_domain_name
      fips_regional_domain_name = replace(aws_s3_bucket.backups.bucket_regional_domain_name, ".s3.", ".s3-fips.")
    }
    blobs = {
      bucket_name               = aws_s3_bucket.blobs.bucket
      id                        = aws_s3_bucket.blobs.id
      policy_json               = data.aws_iam_policy_document.blobs.json
      arn                       = aws_s3_bucket.blobs.arn
      domain_name               = aws_s3_bucket.blobs.bucket_domain_name
      regional_domain_name      = aws_s3_bucket.blobs.bucket_regional_domain_name
      fips_regional_domain_name = replace(aws_s3_bucket.blobs.bucket_regional_domain_name, ".s3.", ".s3-fips.")
    }
    costs = var.storage.costs_enabled ? {
      bucket_name               = aws_s3_bucket.costs[0].bucket
      id                        = aws_s3_bucket.costs[0].id
      policy_json               = data.aws_iam_policy_document.costs[0].json
      arn                       = aws_s3_bucket.costs[0].arn
      domain_name               = aws_s3_bucket.costs[0].bucket_domain_name
      regional_domain_name      = aws_s3_bucket.costs[0].bucket_regional_domain_name
      fips_regional_domain_name = replace(aws_s3_bucket.costs[0].bucket_regional_domain_name, ".s3.", ".s3-fips.")
    } : {}
    logs = {
      bucket_name               = aws_s3_bucket.logs.bucket
      id                        = aws_s3_bucket.logs.id
      policy_json               = data.aws_iam_policy_document.logs.json
      arn                       = aws_s3_bucket.logs.arn
      domain_name               = aws_s3_bucket.logs.bucket_domain_name
      regional_domain_name      = aws_s3_bucket.logs.bucket_regional_domain_name
      fips_regional_domain_name = replace(aws_s3_bucket.logs.bucket_regional_domain_name, ".s3.", ".s3-fips.")
    }
    monitoring = {
      bucket_name               = aws_s3_bucket.monitoring.bucket
      id                        = aws_s3_bucket.monitoring.id
      policy_json               = data.aws_iam_policy_document.monitoring.json
      arn                       = aws_s3_bucket.monitoring.arn
      domain_name               = aws_s3_bucket.monitoring.bucket_domain_name
      regional_domain_name      = aws_s3_bucket.monitoring.bucket_regional_domain_name
      fips_regional_domain_name = replace(aws_s3_bucket.monitoring.bucket_regional_domain_name, ".s3.", ".s3-fips.")
    }
    registry = {
      bucket_name               = aws_s3_bucket.registry.bucket
      id                        = aws_s3_bucket.registry.id
      policy_json               = data.aws_iam_policy_document.registry.json
      arn                       = aws_s3_bucket.registry.arn
      domain_name               = aws_s3_bucket.registry.bucket_domain_name
      regional_domain_name      = aws_s3_bucket.registry.bucket_regional_domain_name
      fips_regional_domain_name = replace(aws_s3_bucket.registry.bucket_regional_domain_name, ".s3.", ".s3-fips.")
    }
  } : k => v if contains(keys(v), "bucket_name") }

  backup_tagging = var.storage.enable_remote_backup ? {
    "backup_plan" = "cross-account"
  } : {}
}
