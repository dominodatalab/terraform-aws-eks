data "aws_caller_identity" "aws_account" {}
data "aws_partition" "current" {}

locals {
  aws_account_id              = data.aws_caller_identity.aws_account.account_id
  kms_key_arn                 = var.kms_info.enabled ? var.kms_info.key_arn : null
  lambda_function_name        = "${var.cur_report_name}-crawler-initializer"
  report_status_table_name    = "cost_and_usage_data_status_tb"
  s3_server_side_encryption   = var.kms_info.enabled ? "aws:kms" : "AES256"
}

resource "aws_cur_report_definition" "aws_cur_report_definition" {
  report_name                = var.cur_report_name
  time_unit                  = var.report_frequency
  format                     = var.report_format
  compression                = var.report_compression
  report_versioning          = var.report_versioning
  additional_artifacts       = ["ATHENA"]
  additional_schema_elements = ["RESOURCES", "SPLIT_COST_ALLOCATION_DATA"]

  s3_bucket = var.cur_report_bucket_name
  s3_region = aws_s3_bucket.cur_report_bucket.region
  s3_prefix = var.s3_bucket_prefix

  depends_on = [
    aws_s3_bucket_policy.cur_report,
  ]
}
