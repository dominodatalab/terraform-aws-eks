data "aws_caller_identity" "aws_account" {}
data "aws_partition" "current" {}
data "aws_default_tags" "this" {}

locals {

  cur_node_groups = {
    for name, ng in
    merge(var.additional_node_groups, var.default_node_groups) :
    name => merge(ng, {
      instance_tags = merge(data.aws_default_tags.this.tags, ng.tags)
    })
  }
}

module "cur_network" {
  source              = "./../network"
  deploy_id           = var.deploy_id
  region              = var.region
  node_groups         = local.cur_node_groups
  network             = var.network
  flow_log_bucket_arn = var.flow_log_bucket_arn
}


locals {
  private_subnet_ids = module.cur_network.info.subnets.private[*].subnet_id
  kms_key            = var.kms.key_id != null ? data.aws_kms_key.key[0] : aws_kms_key.domino[0]
  kms_info = {
    key_id  = local.kms_key.id
    key_arn = local.kms_key.arn
    enabled = var.kms.enabled
  }

  aws_account_id                = data.aws_caller_identity.aws_account.account_id
  kms_key_arn                   = local.kms_info.enabled ? local.kms_info.key_arn : null
  initializer_lambda_function   = "${var.deploy_id}-${var.cur_report_name}-crawler-initializer"
  notification_lambda_function  = "${var.deploy_id}-aws_s3_cur_notification-lambda"
  cur_crawler                   = "${var.deploy_id}-AWSCURCrawler-domino-cur-crawler"
  report_status_table_name      = "cost_and_usage_data_status_tb"
  s3_server_side_encryption     = local.kms_info.enabled ? "aws:kms" : "AES256"
  cur_report_name               = "${var.deploy_id}-${var.cur_report_name}"
  cur_report_bucket             = "${var.deploy_id}-${var.cur_report_bucket_name_suffix}"
  athena_cur_result_bucket_name = "${var.deploy_id}-${var.athena_cur_result_bucket_suffix}"
  aws_glue_database             = "${var.deploy_id}-${var.aws_glue_database_suffix}"

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
  

  report_name                = local.cur_report_name
  time_unit                  = var.report_frequency
  format                     = var.report_format
  compression                = var.report_compression
  report_versioning          = var.report_versioning
  additional_artifacts       = ["ATHENA"]
  additional_schema_elements = ["RESOURCES", "SPLIT_COST_ALLOCATION_DATA"]

  s3_bucket = aws_s3_bucket.cur_report.bucket
  s3_region = var.region
  s3_prefix = var.s3_bucket_prefix

  depends_on = [
    aws_s3_bucket_policy.cur_report,
  ]
}

provider "aws" {
  region = "us-east-1"
  alias  = "domino_cur_region"
  default_tags {
    tags = var.tags
  }
}