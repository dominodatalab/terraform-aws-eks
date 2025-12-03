variable "deploy_id" {
  type        = string
  description = "Domino Deployment ID"

  validation {
    condition     = can(regex("^[a-z-0-9]{3,32}$", var.deploy_id))
    error_message = "Argument deploy_id must: start with a letter, contain lowercase alphanumeric characters(can contain hyphens[-]) with length between 3 and 32 characters."
  }
}

variable "apps_prefix" {
  type        = string
  description = "Prefix for application DNS records (optional). Will be prepended directly before fqdn without a dot."

  default = null

  validation {
    condition     = var.apps_prefix == null || var.apps_prefix != ""
    error_message = "Argument apps_prefix must be null or a non-empty string."
  }
}

variable "load_balancers" {
  description = <<EOF
    List of Load Balancers to create.
    [{
      name     = Name of the Load Balancer.
      type     = Type of Load Balancer (e.g., "application", "network").
      internal = (Optional) Whether the Load Balancer is internal. Defaults to true.
      ddos_protection = (Optional) Whether to enable AWS Shield Standard (DDoS protection). Defaults to true.
      idle_timeout    = (Optional) Connect idle timeout, only used with type "application". Default is 3600.
      listeners = List of listeners for the Load Balancer.
      [{
        name        = Listener name.
        port        = Listener port (e.g., 80, 443).
        protocol    = Protocol used by the listener (e.g., "HTTP", "HTTPS").
        tg_protocol = Protocol used by the target group (e.g., "HTTP", "HTTPS").
        ssl_policy  = (Optional) SSL policy to use for HTTPS listeners.
        cert_arn    = (Optional) ARN of the SSL certificate.
      }]
    }]
  EOF
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
}

variable "waf" {
  description = <<EOF
    Web Application Firewall (WAF) configuration.
    {
      enabled         = Whether WAF is enabled (true/false).
      override_action = (Optional) Override action when a rule matches (default: "none").

      rules = List of WAF rules to apply.
      [{
        name        = Rule name.
        vendor_name = Name of the rule vendor (e.g., "AWS").
        priority    = Rule priority.
        allow       = (Optional) List of conditions to allow.
        block       = (Optional) List of conditions to block.
        captcha     = (Optional) List of CAPTCHA challenge conditions.
        challenge   = (Optional) List of challenge conditions.
        count       = (Optional) List of conditions to count (log only).
      }]

      rate_limit = Rate-based rule configuration.
      {
        enabled = Whether rate limiting is enabled (true/false).
        limit   = Number of requests per 5-minute period before rate limiting.
        action  = Action to take when limit is exceeded ("block", "count", etc.).
      }

      block_forwarder_header = Configuration for header injection on blocked requests.
      {
        enabled = Whether to inject a block forwarder header (true/false).
      }
    }
  EOF
  type = object({
    enabled         = bool
    override_action = optional(string, "none")
    rules = list(object({
      name        = string
      vendor_name = string
      priority    = number
      allow       = optional(list(string), [])
      block       = optional(list(string), [])
      captcha     = optional(list(string), [])
      challenge   = optional(list(string), [])
      count       = optional(list(string), [])
    }))
    rate_limit = object({
      enabled = bool
      limit   = number
      action  = string
    })
    block_forwarder_header = object({
      enabled = bool
    })
  })
}

variable "access_logs" {
  description = <<EOF
    access_logs = {
      enabled   = Enable access logs.
      s3_bucket = The name of the S3 bucket where access logs will be stored.
      s3_prefix = The prefix (folder path) within the S3 bucket for access logs.
    }
  EOF

  type = object({
    enabled   = optional(bool, false)
    s3_bucket = optional(string, null)
    s3_prefix = optional(string, "access_logs/load_balancers")
  })

  validation {
    condition     = !var.access_logs.enabled || (var.access_logs.s3_bucket != null && var.access_logs.s3_bucket != "")
    error_message = "S3 bucket must be provided when access_logs.enabled is true."
  }
}

variable "connection_logs" {
  description = <<EOF
    connection_logs = {
      enabled   = Enable connections logs.
      s3_bucket = The name of the S3 bucket where connection logs will be stored.
      s3_prefix = The prefix (folder path) within the S3 bucket for conneciton logs.
    }
  EOF

  type = object({
    enabled   = optional(bool, false)
    s3_bucket = optional(string, null)
    s3_prefix = optional(string, "connection_logs/load_balancers")
  })

  validation {
    condition     = !var.connection_logs.enabled || (var.connection_logs.s3_bucket != null && var.connection_logs.s3_bucket != "")
    error_message = "S3 bucket must be provided when connection_logs.enabled is true."
  }
}

variable "flow_logs" {
  description = <<EOF
    connection_logs = {
      enabled   = Enable flow logs.
      s3_bucket = The name of the S3 bucket where flow logs will be stored.
      s3_prefix = The prefix (folder path) within the S3 bucket for flow logs.
    }
  EOF

  type = object({
    enabled   = optional(bool, false)
    s3_bucket = optional(string, null)
    s3_prefix = optional(string, "flow_logs/global_accelerator")
  })

  validation {
    condition     = !var.flow_logs.enabled || (var.flow_logs.s3_bucket != null && var.flow_logs.s3_bucket != "")
    error_message = "S3 bucket must be provided when flow_logs.enabled is true."
  }
}

variable "fqdn" {
  description = "Fully qualified domain name (FQDN) of the Domino instance"
  type        = string
}

variable "hosted_zone_name" {
  description = "Full name of the hosted zone"
  type        = string
}

variable "eks_nodes_security_group_id" {
  description = "Security group used by EKS nodes"
  type        = string
}

variable "network_info" {
  description = <<EOF
    vpc_id = VPC ID.
    subnets = {
      public = List of public Subnets.
      [{
        name = Subnet name.
        subnet_id = Subnet ud
        az = Subnet availability_zone
        az_id = Subnet availability_zone_id
      }]
      private = List of private Subnets.
      [{
        name = Subnet name.
        subnet_id = Subnet ud
        az = Subnet availability_zone
        az_id = Subnet availability_zone_id
      }]
    }
  EOF
  type = object({
    vpc_id = string
    subnets = object({
      public = list(object({
        name      = string
        subnet_id = string
        az        = string
        az_id     = string
      }))
      private = optional(list(object({
        name      = string
        subnet_id = string
        az        = string
        az_id     = string
      })), [])
    })
  })
}

variable "use_fips_endpoint" {
  description = "Use aws FIPS endpoints"
  type        = bool
  default     = false
}

variable "hosted_zone_private" {
  description = "Use private hosted zone"
  type        = bool
  default     = false
}
