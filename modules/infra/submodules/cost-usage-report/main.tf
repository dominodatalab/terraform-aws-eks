data "aws_caller_identity" "aws_account" {}
data "aws_partition" "current" {}

locals {
  # private_subnet_ids            = var.network_info.subnets.private[*].subnet_id
  kms_key = var.kms.key_id != null ? data.aws_kms_key.key[0] : aws_kms_key.domino[0]
  kms_info = {
    key_id  = local.kms_key.id
    key_arn = local.kms_key.arn
    enabled = var.kms.enabled
  }

  aws_account_id                = data.aws_caller_identity.aws_account.account_id
  kms_key_arn                   = local.kms_info.enabled ? local.kms_info.key_arn : null
  initializer_lambda_function   = "${var.cur_report_name}-crawler-initializer"
  report_status_table_name      = "cost_and_usage_data_status_tb"
  s3_server_side_encryption     = local.kms_info.enabled ? "aws:kms" : "AES256"
  cur_report_name               = "${var.deploy_id}-${var.cur_report_name}"
  cur_report_bucket             = "${var.deploy_id}-${var.cur_report_bucket_name_suffix}"
  athena_cur_result_bucket_name = "${var.deploy_id}-${var.athena_cur_result_bucket_suffix}"
  aws_glue_database             = "${var.deploy_id}-${var.aws_glue_database_suffix}"
  cur_s3_region                 = "us-east-1"

  s3_buckets = {
    report = {
      bucket_name = aws_s3_bucket.cur_report.bucket
      id          = aws_s3_bucket.cur_report.id
      policy_json = data.aws_iam_policy_document.cur_report.json
      arn         = aws_s3_bucket.cur_report.arn
    }
    athena_result = {
      bucket_name = aws_s3_bucket.athena_result.bucket
      id          = aws_s3_bucket.athena_result.id
      policy_json = data.aws_iam_policy_document.athena_result.json
      arn         = aws_s3_bucket.athena_result.arn
    }
  }
}

resource "aws_cur_report_definition" "aws_cur_report_definition" {
  report_name                = local.cur_report_name
  time_unit                  = var.report_frequency
  format                     = var.report_format
  compression                = var.report_compression
  report_versioning          = var.report_versioning
  additional_artifacts       = ["ATHENA"]
  additional_schema_elements = ["RESOURCES", "SPLIT_COST_ALLOCATION_DATA"]

  s3_bucket = aws_s3_bucket.cur_report.bucket
  s3_region = local.cur_s3_region
  s3_prefix = var.s3_bucket_prefix

  depends_on = [
    aws_s3_bucket_policy.cur_report,
  ]
}
