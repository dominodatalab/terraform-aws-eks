
variable "athena_cur_result_bucket_name" {
  description = "Name of the S3 bucket into which CUR will put the cost data."
  type        = string
  default = "aws-athena-query-results-domino-costs"
}

variable "cur_report_bucket_name" {
  description = "Name of the S3 bucket into which CUR will put the cost data."
  type        = string
  default = "domino-cur-report"
}

variable "s3_use_existing_kms_key" {
  description = "Whether to use an existing KMS CMK for S3 SSE."
  type        = bool
  default = false
}

variable "s3_kms_key_alias" {
  description = "Alias for the KMS CMK, existing or otherwise."
  type        = string
  default     = ""
}

variable "aws_glue_database" {
  description = "Name of the Cost and Usage Report which will be created."
  type        = string
  default = "athena_cur_domino_cost"
}

variable "cur_report_name" {
  description = "Name of the Cost and Usage Report which will be created."
  type        = string
  default = "domino-cur-report"
}

variable "report_frequency" {
  description = "How often the Cost and Usage Report will be generated. HOURLY or DAILY."
  type        = string
  default = "DAILY"
}

variable "report_versioning" {
  description = "Whether reports should be overwritten or new ones should be created."
  type        = string
  default = "OVERWRITE_REPORT"
}

variable "report_format" {
  description = "Format for report. Valid values are: textORcsv, Parquet. If Parquet is used, then Compression must also be Parquet."
  type        = string
  default = "Parquet"
}

variable "report_compression" {
  description = "Compression format for report. Valid values are: GZIP, ZIP, Parquet. If Parquet is used, then format must also be Parquet."
  type        = string
  default = "Parquet"
}

variable "report_additional_artifacts" {
  description = "A list of additional artifacts. Valid values are: REDSHIFT, QUICKSIGHT, ATHENA. When ATHENA exists within additional_artifacts, no other artifact type can be declared and report_versioning must be OVERWRITE_REPORT."
  type        = set(string)
  default = [ "ATHENA" ]
}

variable "s3_bucket_prefix" {
  description = "Prefix in the S3 bucket to put reports."
  type        = string
  default     = "domino-cur"
}

variable "cur_role_arn" {
  description = "ARN of the role to assume in order to provision the Cost and Usage Reports S3 bucket in us-east-1."
  type        = string
  default     = ""
}

variable "cur_role_session_name" {
  description = "Session name to use when assuming `cur_role_arn`."
  type        = string
  default     = null
}

variable "lambda_log_group_retention_days" {
  description = "Number of days to retain logs from the Lambda function, which ensures Glue Crawler runs when new CUR data is available."
  type        = number
  default     = 14
}

variable "glue_crawler_create_log_group" {
  description = "Whether to create a CloudWatch Log Group for the Glue Crawler. Crawlers share Log Group, and this gives the option of managing the Log Group with retention through this module."
  type        = bool
  default     = false
}

variable "glue_crawler_log_group_retention_days" {
  description = "Number of days to retain logs from the Glue Crawler, which populates the Athena table whenever new CUR data is available."
  type        = number
  default     = 14
}

variable "tags" {
  description = "Tags which will be applied to provisioned resources."
  type        = map(string)
  default     = {}
}
