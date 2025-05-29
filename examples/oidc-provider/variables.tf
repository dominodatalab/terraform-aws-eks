variable "deploy_id" {
  type        = string
  description = "Domino Deployment ID"
  nullable    = false
}

variable "region" {
  type        = string
  description = "AWS region for the deployment"
  nullable    = false
}
