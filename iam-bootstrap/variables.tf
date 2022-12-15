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
}

variable "iam_policy_paths" {
  type        = list(any)
  description = "IAM policies to provision and use for deployment role, can be terraform templates"
}

variable "template_config" {
  type        = map
  description = "Variables to use for any templating in the IAM policies. AWS account ID (as 'account_id'), deploy_id and region are automatically included."
  default     = {}
}
