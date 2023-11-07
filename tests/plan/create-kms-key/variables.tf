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

variable "domino_cur" {
  description = "Determines whether to provision domino cost related infrastructures, ie, long term storage"
  type = object({
    provision_resources = optional(bool, false)
    region              = optional(string)
  })

  default = {}
}
