variable "region" {
  description = "AWS region for deployment."
  type        = string
  default     = "us-west-2"
}

variable "deploy_id" {
  description = "Unique name for deployment"
  type        = string
  default     = "dominoeks004"
}
