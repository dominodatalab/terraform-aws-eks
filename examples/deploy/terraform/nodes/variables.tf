## Used to overwrite the `default_node_groups` and `additional_node_groups` variables passed through the `infra` outputs.

variable "default_node_groups" {
  description = "EKS managed node groups definition."
  type = object(
    {
      compute = object(
        {
          single_nodegroup           = optional(bool, false)
          ami                        = optional(string)
          user_data_type             = optional(string)
          bootstrap_extra_args       = optional(string)
          instance_types             = optional(list(string))
          spot                       = optional(bool)
          min_per_az                 = optional(number)
          max_per_az                 = optional(number)
          max_unavailable_percentage = optional(number)
          max_unavailable            = optional(number)
          desired_per_az             = optional(number)
          update_strategy            = optional(string, "DEFAULT")
          availability_zone_ids      = list(string)
          labels                     = optional(map(string))
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
          single_nodegroup           = optional(bool, false)
          ami                        = optional(string)
          user_data_type             = optional(string)
          bootstrap_extra_args       = optional(string)
          instance_types             = optional(list(string))
          spot                       = optional(bool)
          min_per_az                 = optional(number)
          max_per_az                 = optional(number)
          max_unavailable_percentage = optional(number)
          max_unavailable            = optional(number)
          desired_per_az             = optional(number)
          update_strategy            = optional(string, "DEFAULT")
          availability_zone_ids      = list(string)
          labels                     = optional(map(string))
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
          single_nodegroup           = optional(bool, false)
          ami                        = optional(string)
          user_data_type             = optional(string)
          bootstrap_extra_args       = optional(string)
          instance_types             = optional(list(string))
          spot                       = optional(bool)
          min_per_az                 = optional(number)
          max_per_az                 = optional(number)
          max_unavailable_percentage = optional(number)
          max_unavailable            = optional(number)
          desired_per_az             = optional(number)
          update_strategy            = optional(string, "DEFAULT")
          availability_zone_ids      = list(string)
          labels                     = optional(map(string))
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
    single_nodegroup           = optional(bool, false)
    ami                        = optional(string)
    user_data_type             = optional(string)
    bootstrap_extra_args       = optional(string)
    instance_types             = list(string)
    spot                       = optional(bool)
    min_per_az                 = number
    max_per_az                 = number
    max_unavailable_percentage = optional(number)
    max_unavailable            = optional(number)
    desired_per_az             = number
    update_strategy            = optional(string, "DEFAULT")
    availability_zone_ids      = list(string)
    labels                     = map(string)
    taints = optional(list(object({
      key    = string
      value  = optional(string)
      effect = string
    })))
    tags   = optional(map(string), {})
    gpu    = optional(bool)
    neuron = optional(bool)
    volume = object({
      size = string
      type = string
    })
  }))
  default = null
}


variable "use_fips_endpoint" {
  description = "Use aws FIPS endpoints"
  type        = bool
  default     = false
}


variable "karpenter_node_groups" {
  description = "Node groups for karpenter."
  type = map(object({
    single_nodegroup           = optional(bool, false)
    ami                        = optional(string, null)
    user_data_type             = optional(string, null)
    bootstrap_extra_args       = optional(string, "")
    instance_types             = optional(list(string), ["m6a.large"])
    spot                       = optional(bool, false)
    min_per_az                 = optional(number, 1)
    max_per_az                 = optional(number, 3)
    max_unavailable_percentage = optional(number, null)
    max_unavailable            = optional(number, 1)
    update_strategy            = optional(string, "MINIMAL")
    desired_per_az             = optional(number, 1)
    availability_zone_ids      = list(string)
    labels = optional(map(string), {
      "dominodatalab.com/node-pool"           = "karpenter"
      "dominodatalab.com/calico-controlplane" = "true"
    })
    taints = optional(list(object({
      key    = string
      value  = optional(string)
      effect = string
    })), [])
    tags = optional(map(string), {})
    gpu  = optional(bool, null)
    volume = optional(object({
      size       = optional(string, "30")
      type       = optional(string, "gp3")
      iops       = optional(number)
      throughput = optional(number, 500)
    }), {})
  }))
  default = null
}
