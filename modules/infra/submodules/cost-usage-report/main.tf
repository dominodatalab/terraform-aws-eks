data "aws_caller_identity" "aws_account" {}
data "aws_partition" "current" {}

locals {
  private_subnet_ids = var.network_info.subnets.private[*].subnet_id

  aws_account_id                = data.aws_caller_identity.aws_account.account_id
  kms_key_arn                   = var.kms_info.enabled ? var.kms_info.key_arn : null
  initializer_lambda_function   = "${var.deploy_id}-${var.cur.report_name}-crawler-initializer"
  notification_lambda_function  = "${var.deploy_id}-aws_s3_cur_notification-lambda"
  cur_crawler                   = "${var.deploy_id}-AWSCURCrawler-domino-cur-crawler"
  report_status_table_name      = "cost_and_usage_data_status_tb"
  s3_server_side_encryption     = var.kms_info.enabled ? "aws:kms" : "AES256"
  report_name               = "${var.deploy_id}-${var.cur.report_name}"
  cur_report_bucket             = "${var.deploy_id}-${var.cur.report_bucket_name_suffix}"
  athena_cur_result_bucket_name = "${var.deploy_id}-${var.cur.athena_result_bucket_suffix}"
  aws_glue_database             = "${var.deploy_id}-${var.cur.aws_glue_database_suffix}"

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
  provider = aws.domino_cur_region

  report_name                = local.report_name
  time_unit                  = var.cur.report_frequency
  format                     = var.cur.report_format
  compression                = var.cur.report_compression
  report_versioning          = var.cur.report_versioning
  additional_artifacts       = ["ATHENA"]
  additional_schema_elements = ["RESOURCES", "SPLIT_COST_ALLOCATION_DATA"]

  s3_bucket = aws_s3_bucket.cur_report.bucket
  s3_region = var.region
  s3_prefix = var.cur.s3_bucket_prefix

  depends_on = [
    aws_s3_bucket_policy.cur_report,
  ]
}

provider "aws" { alias = "domino_cur_region" }