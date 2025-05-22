variable "deploy_id" {
  type        = string
  description = "Domino Deployment ID"

  validation {
    condition     = can(regex("^[a-z-0-9]{3,32}$", var.deploy_id))
    error_message = "Argument deploy_id must: start with a letter, contain lowercase alphanumeric characters(can contain hyphens[-]) with length between 3 and 32 characters."
  }
}

variable "flow_logs" {
  description = <<EOF
    flow_logs = {
      enabled   = Enable store for flow logs.
      s3_bucket = The name of the S3 bucket where flow logs will be stored.
      s3_prefix = The prefix (folder path) within the S3 bucket for storing logs.
    }
  EOF

  type = object({
    enabled   = optional(bool, false)
    s3_bucket = string
    s3_prefix = optional(string, "access_logs/global_accelerator")
  })
}