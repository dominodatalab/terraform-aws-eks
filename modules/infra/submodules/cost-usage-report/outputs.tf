output "cur_report_bucket_name" {
  description = "Name of S3 bucket used for storing CUR data. This may be provisioned by this module or not."
  value       = aws_cur_report_definition.aws_cur_report_definition.s3_bucket
}

output "s3_bucket_prefix" {
  description = "Prefix used for storing CUR data inside the S3 bucket."
  value       = aws_cur_report_definition.aws_cur_report_definition.s3_prefix
}

output "s3_bucket_arn" {
  description = "ARN of S3 bucket used for storing CUR data. This may be provisioned by this module or not."
  value       = aws_s3_bucket.cur_report_bucket.*.arn
}

output "s3_bucket_region" {
  description = "Region where the S3 bucket used for storing CUR data is provisioned. This may be provisioned by this module or not."
  value       = aws_cur_report_definition.aws_cur_report_definition.s3_region
}

output "report_name" {
  description = "Name of the provisioned Cost and Usage Report."
  value       = aws_cur_report_definition.aws_cur_report_definition.report_name
}

output "lambda_crawler_trigger_arn" {
  description = "ARN of the Lambda function responsible for triggering the Glue Crawler when new CUR data is uploaded into the S3 bucket."
  value       = aws_lambda_function.aws_cur_initializer.arn
}

output "lambda_crawler_trigger_role_arn" {
  description = "ARN of the IAM role used by the Lambda function responsible for starting the Glue Crawler."
  value       = aws_iam_role.aws_cur_crawler_lambda_executor.arn
}

output "crawler_arn" {
  description = "ARN of the Glue Crawler responsible for populating the Catalog Database with new CUR data."
  value       = aws_lambda_function.aws_cur_initializer.arn
}

output "crawler_role_arn" {
  description = "ARN of the IAM role used by the Glue Crawler responsible for populating the Catalog Database with new CUR data."
  value       = aws_iam_role.aws_cur_crawler_component_function_role.arn
}

output "athena_region" {
  description = "athena region"
  value       = aws_cur_report_definition.aws_cur_report_definition.s3_region
}

output "glue_catalog_database_name" {
  description = "Name of the Glue Catalog Database which is populated with CUR data."
  value       = aws_glue_catalog_database.aws_cur_database.name
}

output "glue_catalog_table_name" {
  description = "Name of the Glue Catalog table which is populated with CUR data."
  value       = aws_glue_catalog_table.aws_cur_report_status_table.name
}

output "athena_query_result_s3" {
  value = aws_s3_bucket.athena_result_bucket.bucket
}