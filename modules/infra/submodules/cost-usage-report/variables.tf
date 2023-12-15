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

variable "cost_usage_report" {
  description = <<EOF
    athena_result_bucket_suffix = Name of the S3 bucket into which Athena will put the cost data.
    report_bucket_name_suffix = Suffix of the S3 bucket into which CUR will put the cost data.
    aws_glue_database_suffix = Suffix of the Glue's DB.
    report_name = Name of the Cost and Usage Report which will be created.
    report_frequency = How often the Cost and Usage Report will be generated. HOURLY or DAILY.
    report_versioning = Whether reports should be overwritten or new ones should be created.
    report_format = Format for report. Valid values are: textORcsv, Parquet. If Parquet is used, then Compression must also be Parquet.
    report_compression = Compression format for report. Valid values are: GZIP, ZIP, Parquet. If Parquet is used, then format must also be Parquet.
    s3_bucket_prefix = Prefix in the S3 bucket to put reports.
  EOF
  type = object({
    athena_result_bucket_suffix = string
    report_bucket_name_suffix   = string
    aws_glue_database_suffix    = string
    report_name                 = string
    report_frequency            = string
    report_versioning           = string
    report_format               = string
    report_compression          = string
    s3_bucket_prefix            = string
  })
  default = {
    athena_result_bucket_suffix = "aws-athena-query-results-costs"
    report_bucket_name_suffix   = "cur-report"
    aws_glue_database_suffix    = "athena-cur-cost-db"
    report_name                 = "cur-report"
    report_frequency            = "DAILY"
    report_versioning           = "OVERWRITE_REPORT"
    report_format               = "Parquet"
    report_compression          = "Parquet"
    s3_bucket_prefix            = "cur"
  }
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

variable "network_info" {
  description = <<EOF
    vpc_id = VPC ID.
    subnets = {
      public = List of public Subnets.
      [{
        name = Subnet name.
        subnet_id = Subnet ud
        az = Subnet availability_zone
        az_id = Subnet availability_zone_id
      }]
      private = List of private Subnets.
      [{
        name = Subnet name.
        subnet_id = Subnet ud
        az = Subnet availability_zone
        az_id = Subnet availability_zone_id
      }]
      pod = List of pod Subnets.
      [{
        name = Subnet name.
        subnet_id = Subnet ud
        az = Subnet availability_zone
        az_id = Subnet availability_zone_id
      }]
    }
  EOF
  type = object({
    vpc_id = string
    subnets = object({
      public = list(object({
        name      = string
        subnet_id = string
        az        = string
        az_id     = string
      }))
      private = optional(list(object({
        name      = string
        subnet_id = string
        az        = string
        az_id     = string
      })), [])
      pod = optional(list(object({
        name      = string
        subnet_id = string
        az        = string
        az_id     = string
      })), [])
    })
  })
}
