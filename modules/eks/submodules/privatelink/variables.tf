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

variable "vpc_endpoint_services" {
  description = <<EOF
    [{
      name      = Name of the VPC Endpoint Service.
      ports     = List of ports exposing the VPC Endpoint Service. i.e [8080, 8081]
      cert_arn  = Certificate ARN used by the NLB associated for the given VPC Endpoint Service.
      private_dns = Private DNS for the VPC Endpoint Service.
    }]
  EOF

  type = list(object({
    name        = optional(string)
    ports       = optional(list(number))
    cert_arn    = optional(string)
    private_dns = optional(string)
  }))
}

variable "route53_hosted_zone_name" {
  type        = string
  description = "Hosted zone for External DNS zone."
  nullable    = false
}

variable "network_info" {
  description = <<EOF
    {
      vpc_id = VPC Id.
      subnets = {
        private = Private subnets.
        public  = Public subnets.
        pod     = Pod subnets.
      }), {})
    }), {})
  EOF

  type = object({
    vpc_id = string
    subnets = object({
      private = list(object({
        name      = string
        subnet_id = string
        az        = string
        az_id     = string
      }))
      public = list(object({
        name      = string
        subnet_id = string
        az        = string
        az_id     = string
      }))
      pod = list(object({
        name      = string
        subnet_id = string
        az        = string
        az_id     = string
      }))
    })
  })
}

variable "oidc_provider_id" {
  type        = string
  description = "OIDC Provider ID"
  nullable    = false
}

variable "namespace" {
  type        = string
  description = "Namespace for IAM Policy conditions"
  default     = "domino-platform"
  nullable    = false
}

variable "monitoring_bucket" {
  type        = string
  description = "Monitoring bucket"
  nullable    = false
}