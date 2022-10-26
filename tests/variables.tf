variable "deploy_id" {
  type        = string
  description = "Domino Deployment ID."
}


variable "region" {
  type        = string
  description = "AWS region for the deployment"
  default     = "us-west-2"
}


variable "tags" {
  type        = map(string)
  description = "Deployment tags."
}

variable "k8s_version" {
  type        = string
  description = "EKS cluster k8s version."
  default     = "1.23"
}
