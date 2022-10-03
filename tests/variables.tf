variable "deploy_id" {
  type        = string
  description = "Domino Deployment ID."
  default     = "mhtest3"
}


variable "region" {
  type        = string
  description = "AWS region for the deployment"
  default     = "us-west-2"
}


variable "tags" {
  type        = map(string)
  description = "Deployment tags."
  default = {
    deploy_id        = "mhtest3"
    deploy_tag       = "mhtest3"
    deploy_type      = "terraform-aws-eks"
    domino-deploy-id = "mhtest3"
  }
}

variable "k8s_version" {
  type        = string
  description = "EKS cluster k8s version."
  default     = "1.23"
}
