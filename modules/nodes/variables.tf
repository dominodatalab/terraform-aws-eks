
variable "default_node_groups" {
  description = "EKS managed node groups definition."
  type = object(
    {
      compute = object(
        {
          ami                   = optional(string)
          bootstrap_extra_args  = optional(string)
          instance_types        = optional(list(string))
          spot                  = optional(bool)
          min_per_az            = optional(number)
          max_per_az            = optional(number)
          desired_per_az        = optional(number)
          availability_zone_ids = list(string)
          labels                = optional(map(string))
          taints = optional(list(object({
            key    = string
            value  = optional(string)
            effect = string
          })))
          tags = optional(map(string))
          gpu  = optional(bool)
          volume = optional(object({
            size = optional(number)
            type = optional(string)
            })
          )
      }),
      platform = object(
        {
          ami                   = optional(string)
          bootstrap_extra_args  = optional(string)
          instance_types        = optional(list(string))
          spot                  = optional(bool)
          min_per_az            = optional(number)
          max_per_az            = optional(number)
          desired_per_az        = optional(number)
          availability_zone_ids = list(string)
          labels                = optional(map(string))
          taints = optional(list(object({
            key    = string
            value  = optional(string)
            effect = string
          })))
          tags = optional(map(string))
          gpu  = optional(bool)
          volume = optional(object({
            size = optional(number)
            type = optional(string)
          }))
      }),
      gpu = object(
        {
          ami                   = optional(string)
          bootstrap_extra_args  = optional(string)
          instance_types        = optional(list(string))
          spot                  = optional(bool)
          min_per_az            = optional(number)
          max_per_az            = optional(number)
          desired_per_az        = optional(number)
          availability_zone_ids = list(string)
          labels                = optional(map(string))
          taints = optional(list(object({
            key    = string
            value  = optional(string)
            effect = string
          })))
          tags = optional(map(string), {})
          gpu  = optional(bool, null)
          volume = optional(object({
            size = optional(number)
            type = optional(string)
          }))
      })
  })
  default = null
}

variable "additional_node_groups" {
  description = "Additional EKS managed node groups definition."
  type = map(object({
    ami                   = optional(string)
    bootstrap_extra_args  = optional(string)
    instance_types        = list(string)
    spot                  = optional(bool)
    min_per_az            = number
    max_per_az            = number
    desired_per_az        = number
    availability_zone_ids = list(string)
    labels                = map(string)
    taints = optional(list(object({
      key    = string
      value  = optional(string)
      effect = string
    })))
    tags = optional(map(string), {})
    gpu  = optional(bool)
    volume = object({
      size = string
      type = string
    })
  }))
  default = {
      "extra_group" = {
          instance_types = ["m5.2xlarge"]
          min_per_az = 0
          max_per_az = 10
          desired_per_az = 0
          availability_zone_ids = ["usw2-az1"]
          labels = {}
          volume = {
              size = 100
              type = "gp3"
          }
      }
  }
}

variable "infra_state_file" {
  description = "Path to statefile for infra module"
  type        = string
  default     = null
}

variable "cluster_state_file" {
  description = "Path to statefile for cluster module"
  type        = string
  default     = null
}
