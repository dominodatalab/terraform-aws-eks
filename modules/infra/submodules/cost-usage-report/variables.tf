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


variable "network" {
  description = <<EOF
    vpc = {
      id = Existing vpc id, it will bypass creation by this module.
      subnets = {
        private = Existing private subnets.
        public  = Existing public subnets.
        pod     = Existing pod subnets.
      }), {})
    }), {})
    network_bits = {
      public  = Number of network bits to allocate to the public subnet. i.e /27 -> 32 IPs.
      private = Number of network bits to allocate to the private subnet. i.e /19 -> 8,192 IPs.
      pod     = Number of network bits to allocate to the private subnet. i.e /19 -> 8,192 IPs.
    }
    cidrs = {
      vpc     = The IPv4 CIDR block for the VPC.
      pod     = The IPv4 CIDR block for the Pod subnets.
    }
    use_pod_cidr = Use additional pod CIDR range (ie 100.64.0.0/16) for pod networking.
  EOF

  type = object({
    vpc = optional(object({
      id = optional(string, null)
      subnets = optional(object({
        private = optional(list(string), [])
        public  = optional(list(string), [])
        pod     = optional(list(string), [])
      }), {})
    }), {})
    network_bits = optional(object({
      public  = optional(number, 27)
      private = optional(number, 19)
      pod     = optional(number, 19)
      }
    ), {})
    cidrs = optional(object({
      vpc = optional(string, "10.0.0.0/16")
      pod = optional(string, "100.64.0.0/16")
    }), {})
    use_pod_cidr = optional(bool, true)
  })

  default = {}
}

## This is an object in order to be used as a conditional in count, due to https://github.com/hashicorp/terraform/issues/26755
variable "flow_log_bucket_arn" {
  type        = object({ arn = string })
  description = "Bucket for vpc flow logging"
  default     = null
}

variable "default_node_groups" {
  description = "EKS managed node groups definition."
  type = object(
    {
      compute = object(
        {
          ami                   = optional(string, null)
          bootstrap_extra_args  = optional(string, "")
          instance_types        = optional(list(string), ["m5.2xlarge"])
          spot                  = optional(bool, false)
          min_per_az            = optional(number, 0)
          max_per_az            = optional(number, 10)
          desired_per_az        = optional(number, 0)
          availability_zone_ids = list(string)
          labels = optional(map(string), {
            "dominodatalab.com/node-pool" = "default"
          })
          taints = optional(list(object({
            key    = string
            value  = optional(string)
            effect = string
          })), [])
          tags = optional(map(string), {})
          gpu  = optional(bool, null)
          volume = optional(object({
            size = optional(number, 1000)
            type = optional(string, "gp3")
            }), {
            size = 1000
            type = "gp3"
            }
          )
      }),
      platform = object(
        {
          ami                   = optional(string, null)
          bootstrap_extra_args  = optional(string, "")
          instance_types        = optional(list(string), ["m5.2xlarge"])
          spot                  = optional(bool, false)
          min_per_az            = optional(number, 1)
          max_per_az            = optional(number, 10)
          desired_per_az        = optional(number, 1)
          availability_zone_ids = list(string)
          labels = optional(map(string), {
            "dominodatalab.com/node-pool" = "platform"
          })
          taints = optional(list(object({
            key    = string
            value  = optional(string)
            effect = string
          })), [])
          tags = optional(map(string), {})
          gpu  = optional(bool, null)
          volume = optional(object({
            size = optional(number, 100)
            type = optional(string, "gp3")
            }), {
            size = 100
            type = "gp3"
            }
          )
      }),
      gpu = object(
        {
          ami                   = optional(string, null)
          bootstrap_extra_args  = optional(string, "")
          instance_types        = optional(list(string), ["g4dn.xlarge"])
          spot                  = optional(bool, false)
          min_per_az            = optional(number, 0)
          max_per_az            = optional(number, 10)
          desired_per_az        = optional(number, 0)
          availability_zone_ids = list(string)
          labels = optional(map(string), {
            "dominodatalab.com/node-pool" = "default-gpu"
            "nvidia.com/gpu"              = true
          })
          taints = optional(list(object({
            key    = string
            value  = optional(string)
            effect = string
            })), [{
            key    = "nvidia.com/gpu"
            value  = "true"
            effect = "NO_SCHEDULE"
            }
          ])
          tags = optional(map(string), {})
          gpu  = optional(bool, null)
          volume = optional(object({
            size = optional(number, 1000)
            type = optional(string, "gp3")
            }), {
            size = 1000
            type = "gp3"
            }
          )
      })
  })
}

variable "additional_node_groups" {
  description = "Additional EKS managed node groups definition."
  type = map(object({
    ami                   = optional(string, null)
    bootstrap_extra_args  = optional(string, "")
    instance_types        = list(string)
    spot                  = optional(bool, false)
    min_per_az            = number
    max_per_az            = number
    desired_per_az        = number
    availability_zone_ids = list(string)
    labels                = map(string)
    taints = optional(list(object({
      key    = string
      value  = optional(string)
      effect = string
    })), [])
    tags = optional(map(string), {})
    gpu  = optional(bool, null)
    volume = object({
      size = string
      type = string
    })
  }))

  default = {}
}
