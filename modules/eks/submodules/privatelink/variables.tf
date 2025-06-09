variable "deploy_id" {
  type        = string
  description = "Domino Deployment ID"

  validation {
    condition     = can(regex("^[a-z-0-9]{3,32}$", var.deploy_id))
    error_message = "Argument deploy_id must: start with a letter, contain lowercase alphanumeric characters(can contain hyphens[-]) with length between 3 and 32 characters."
  }
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
    vpc_cidrs = string
  })
}

variable "privatelink" {
  description = <<EOF
    {
      enabled = Enable Private Link connections.
      monitoring_bucket = Bucket for NLBs monitoring.
      route53_hosted_zone_name = Hosted zone for External DNS zone.
      vpc_endpoint_services = [{
        name      = Name of the VPC Endpoint Service.
        ports     = List of ports exposing the VPC Endpoint Service. i.e [8080, 8081]
        cert_arn  = Certificate ARN used by the NLB associated for the given VPC Endpoint Service.
        private_dns = Private DNS for the VPC Endpoint Service.
        supported_regions = The set of regions from which service consumers can access the service.
      }]
    }
  EOF


  type = object({
    enabled                  = optional(bool, false)
    monitoring_bucket        = optional(string, null)
    route53_hosted_zone_name = optional(string, null)
    vpc_endpoint_services = optional(list(object({
      name              = optional(string)
      ports             = optional(list(number))
      cert_arn          = optional(string)
      private_dns       = optional(string)
      supported_regions = optional(set(string))
    })), [])
  })

  validation {
    condition     = !var.privatelink.enabled || (var.privatelink.enabled && var.privatelink.route53_hosted_zone_name != null)
    error_message = "Route53 Hosted Zone Name cannot be null"
  }

  default = {}
}
