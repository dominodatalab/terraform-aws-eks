resource "aws_cur_report_definition" "aws_cur_report_definition" {
  report_name                = var.cur_report_name
  time_unit                  = var.report_frequency
  format                     = var.report_format
  compression                = var.report_compression
  report_versioning          = var.report_versioning
  additional_artifacts       = ["ATHENA" ]
  additional_schema_elements = ["RESOURCES", "SPLIT_COST_ALLOCATION_DATA"]

  s3_bucket = var.cur_report_bucket_name
  s3_region = aws_s3_bucket.cur_report_bucket.region
  s3_prefix = var.s3_bucket_prefix

  depends_on = [
    aws_s3_bucket_policy.cur_report,
  ]

  provider = aws.cur
}

data "aws_kms_key" "s3" {
  count = var.s3_use_existing_kms_key ? 1 : 0

  key_id = "alias/${trimprefix(var.s3_kms_key_alias, "alias/")}"
}


resource "aws_kms_key" "s3" {
  count = var.s3_use_existing_kms_key ? 0 : 1

  description = "For server-side encryption in the '${var.cur_report_bucket_name}' S3 bucket."

  tags = var.tags
}
