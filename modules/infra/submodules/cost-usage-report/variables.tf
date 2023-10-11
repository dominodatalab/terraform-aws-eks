
variable "athena_cur_result_bucket_name" {
  description = "Name of the S3 bucket into which CUR will put the cost data."
  type        = string
  default     = "aws-athena-query-results-domino-costs"
}

variable "cur_report_bucket_name" {
  description = "Name of the S3 bucket into which CUR will put the cost data."
  type        = string
  default     = "domino-cur-report"
}

variable "aws_glue_database" {
  description = "Name of the Cost and Usage Report which will be created."
  type        = string
  default     = "athena_cur_domino_cost"
}

variable "cur_report_name" {
  description = "Name of the Cost and Usage Report which will be created."
  type        = string
  default     = "domino-cur-report"
}

variable "report_frequency" {
  description = "How often the Cost and Usage Report will be generated. HOURLY or DAILY."
  type        = string
  default     = "DAILY"
}

variable "report_versioning" {
  description = "Whether reports should be overwritten or new ones should be created."
  type        = string
  default     = "OVERWRITE_REPORT"
}

variable "report_format" {
  description = "Format for report. Valid values are: textORcsv, Parquet. If Parquet is used, then Compression must also be Parquet."
  type        = string
  default     = "Parquet"
}

variable "report_compression" {
  description = "Compression format for report. Valid values are: GZIP, ZIP, Parquet. If Parquet is used, then format must also be Parquet."
  type        = string
  default     = "Parquet"
}

variable "s3_bucket_prefix" {
  description = "Prefix in the S3 bucket to put reports."
  type        = string
  default     = "domino-cur"
}

variable "tags" {
  description = "Tags which will be applied to provisioned resources."
  type        = map(string)
  default     = {}
}

variable "kms_info" {
  description = <<EOF
    key_id  = KMS key id.
    key_arn = KMS key arn.
    enabled = KMS key is enabled
  EOF
  type = object({
    key_id  = string
    key_arn = string
    enabled = bool
  })
}

