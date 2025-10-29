
variable "instance_capacity" {
  description = <<EOF
    Creates a capacity reservation for each instance_type on each zone.
    instance_types        = List of instance types to create a capacity reservation for.
    capacity              = Number of instances to reserve
    availability_zone_ids = List of azs to create a capacity reservation in.
    }
  EOF
  nullable    = false
  type = map(object({
    instance_types        = list(string)
    capacity              = number
    availability_zone_ids = list(string)
  }))
  default = {}
}

variable "region" {
  type        = string
  description = "AWS region for the deployment"
  nullable    = false
  validation {
    condition     = can(regex("(us(-gov)?|ap|ca|cn|eu|sa|me|af)-(central|(north|south)?(east|west)?)-[0-9]", var.region))
    error_message = "The provided region must follow the format of AWS region names, e.g., us-west-2, us-gov-west-1."
  }
}

variable "tags" {
  type        = map(string)
  description = "Deployment tags."
  default     = {}
}

variable "ignore_tags" {
  type        = list(string)
  description = "Tag keys to be ignored by the aws provider."
  default     = []
}

variable "partner_tags" {
  type        = map(string)
  description = "Domino AWS partner tags"
  default     = { "aws-apn-id" : "pc:2umrgw02q6y8t2te66fgdx6sk" }
}

variable "use_fips_endpoint" {
  description = "Use aws FIPS endpoints"
  type        = bool
  default     = false
}
