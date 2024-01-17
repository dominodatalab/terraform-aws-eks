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

variable "iam_policy_paths" {
  type        = list(any)
  description = "IAM policies to provision and use for deployment role, can be terraform templates"
  default     = []
}

variable "template_config" {
  type        = map(any)
  description = "Variables to use for any templating in the IAM policies. AWS account ID (as 'account_id'), deploy_id, region and partition are automatically included."
  default     = {}
}

variable "max_session_duration" {
  type        = number
  description = "Maximum session duration for role in seconds"
  default     = 43200
}

variable "ignore_tag_keys" {
  type        = list(string)
  description = "Tag keys to be ignored by the aws provider."
  default     = []
}
