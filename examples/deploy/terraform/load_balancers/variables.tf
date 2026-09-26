## Mirrors the input contract of modules/load-balancers and modules/privatelink. Leave
## `load_balancers` as its default `[]` to skip this stack entirely (e.g. private-link-only
## or bastion-only deployments that don't front the cluster with an ALB/NLB + Global
## Accelerator).

variable "load_balancers" {
  description = "List of Load Balancers to create. See modules/load-balancers variables.tf for the full shape."
  type = list(object({
    name            = string
    type            = string
    internal        = optional(bool, true)
    ddos_protection = optional(bool, true)
    idle_timeout    = optional(number, 3600)
    listeners = list(object({
      name                = string
      port                = number
      protocol            = string
      tg_protocol         = string
      tg_protocol_version = optional(string)
      ssl_policy          = optional(string)
      cert_arn            = optional(string)
    }))
  }))
  default = []
}

variable "waf" {
  description = "Web Application Firewall (WAF) configuration applied to the load balancers. See modules/load-balancers variables.tf for the full shape."
  type = object({
    enabled         = bool
    override_action = optional(string, "none")
    rules = optional(list(object({
      name        = string
      vendor_name = string
      priority    = number
      allow       = optional(list(string), [])
      block       = optional(list(string), [])
      captcha     = optional(list(string), [])
      challenge   = optional(list(string), [])
      count       = optional(list(string), [])
    })), [])
    rate_limit = object({
      enabled = bool
      limit   = number
      action  = string
    })
    block_forwarder_header = object({
      enabled = bool
    })
  })
  default = {
    enabled = false
    rate_limit = {
      enabled = false
      limit   = 1000
      action  = "count"
    }
    block_forwarder_header = {
      enabled = false
    }
  }
}

variable "access_logs" {
  description = "Enable ALB/NLB access logs. Stored in the infra monitoring bucket."
  type = object({
    enabled = optional(bool, false)
  })
  default = {}
}

variable "connection_logs" {
  description = "Enable NLB connection logs. Stored in the infra monitoring bucket."
  type = object({
    enabled = optional(bool, false)
  })
  default = {}
}

variable "flow_logs" {
  description = "Enable Global Accelerator flow logs. Stored in the infra monitoring bucket."
  type = object({
    enabled = optional(bool, false)
  })
  default = {}
}

variable "route53_hosted_zone_name" {
  description = "Route53 hosted zone name to create the Domino instance's DNS records in."
  type        = string
  default     = null
}

variable "hosted_zone_private" {
  description = "Whether the Route53 hosted zone is private."
  type        = bool
  default     = false
}

variable "privatelink" {
  description = "PrivateLink configuration fronting the load balancers created by this stack. See modules/privatelink variables.tf for the full shape."
  type = object({
    enabled                  = optional(bool, false)
    route53_hosted_zone_name = optional(string, null)
    vpc_endpoint_services = optional(list(object({
      name              = optional(string)
      lb_name           = optional(string)
      private_dns       = optional(string)
      supported_regions = optional(set(string))
    })), [])
  })
  default = {}
}

variable "use_fips_endpoint" {
  description = "Use aws FIPS endpoints"
  type        = bool
  default     = false
}
