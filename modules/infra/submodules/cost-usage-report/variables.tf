variable "deploy_id" {
  type        = string
  description = "Domino Deployment ID"

  validation {
    condition     = can(regex("^[a-z-0-9]{3,32}$", var.deploy_id))
    error_message = "Argument deploy_id must: start with a letter, contain lowercase alphanumeric characters(can contain hyphens[-]) with length between 3 and 32 characters."
  }
}

variable "region" {
  type        = string
  description = "AWS region for the deployment"
  nullable    = false
  validation {
    condition     = can(regex("(us(-gov)?|ap|ca|cn|eu|sa|me|af|il)-(central|(north|south)?(east|west)?)-[0-9]", var.region))
    error_message = "The provided region must follow the format of AWS region names, e.g., us-west-2, us-gov-west-1."
  }
}

variable "athena_cur_result_bucket_suffix" {
  description = "Name of the S3 bucket into which CUR will put the cost data."
  type        = string
  default     = "aws-athena-query-results-costs"
}

variable "cur_report_bucket_name_suffix" {
  description = "Name of the S3 bucket into which CUR will put the cost data."
  type        = string
  default     = "cur-report"
}

variable "aws_glue_database_suffix" {
  description = "Name of the Cost and Usage Report which will be created."
  type        = string
  default     = "athena-cur-cost-db"
}

variable "cur_report_name" {
  description = "Name of the Cost and Usage Report which will be created."
  type        = string
  default     = "cur-report"
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
  default     = "cur"
}

variable "tags" {
  description = "Tags which will be applied to provisioned resources."
  type        = map(string)
  default     = {}
}

# variable "kms_info" {
#   description = <<EOF
#     key_id  = KMS key id.
#     key_arn = KMS key arn.
#     enabled = KMS key is enabled
#   EOF
#   type = object({
#     key_id  = string
#     key_arn = string
#     enabled = bool
#   })
# }

variable "kms" {
  description = <<EOF
    enabled             = "Toggle, if set use either the specified KMS key_id or a Domino-generated one"
    key_id              = optional(string, null)
    additional_policies = "Allows setting additional KMS key policies when using a Domino-generated key"
  EOF

  type = object({
    enabled             = optional(bool, true)
    key_id              = optional(string, null)
    additional_policies = optional(list(string), [])
  })

  validation {
    condition     = var.kms.enabled && var.kms.key_id != null ? length(var.kms.key_id) > 0 : true
    error_message = "KMS key ID must be null or set to a non-empty string, when var.kms.enabled is."
  }

  validation {
    condition     = var.kms.key_id != null ? var.kms.enabled : true
    error_message = "var.kms.enabled must be true if var.kms.key_id is provided."
  }

  validation {
    condition     = var.kms.key_id != null ? length(var.kms.additional_policies) == 0 : true
    error_message = "var.kms.additional_policies cannot be provided if if var.kms.key_id is provided."
  }

  default = {}
}