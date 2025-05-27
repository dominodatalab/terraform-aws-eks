variable "deploy_id" {
  type        = string
  description = "Domino Deployment ID"

  validation {
    condition     = can(regex("^[a-z-0-9]{3,32}$", var.deploy_id))
    error_message = "Argument deploy_id must: start with a letter, contain lowercase alphanumeric characters(can contain hyphens[-]) with length between 3 and 32 characters."
  }
}

variable "load_balancers" {
  description = "Lista de load balancers a crear"
  type = list(object({
    name     = string
    type     = string
    internal = bool
    listeners = list(object({
      port       = number
      protocol   = string
      ssl_policy = optional(string)
      cert_arn   = optional(string)
    }))
  }))
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
    s3_bucket = string
    s3_prefix = optional(string, "access_logs/load_balancers")
  })
}

variable "connection_logs" {
  description = <<EOF
    access_logs = {
      enabled   = Enable connections logs.
      s3_bucket = The name of the S3 bucket where connection logs will be stored.
      s3_prefix = The prefix (folder path) within the S3 bucket for conneciton logs.
    }
  EOF

  type = object({
    enabled   = optional(bool, false)
    s3_bucket = string
    s3_prefix = optional(string, "connection_logs/load_balancers")
  })
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