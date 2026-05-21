
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
    condition     = can(regex("^[a-z]{2,}(-[a-z0-9]+)*-\\w+-\\d+$", var.region))
    error_message = "The provided region must follow the format of AWS region names, e.g., us-west-2, us-gov-west-1, us-iso-east-1."
  }
}
