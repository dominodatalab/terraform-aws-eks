variable "region" {
  description = "AWS region for deployment."
  type        = string
  default     = "us-west-2"
}

variable "deploy_id" {
  description = "Deployment ID."
  type        = string
  default     = "dominoeks003"
}

variable "ignore_tag_keys" {
  type        = list(string)
  description = "Tag keys to be ignored by the aws provider."
  default     = []
}
