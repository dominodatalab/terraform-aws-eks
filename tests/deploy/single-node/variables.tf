variable "single_node" {
  description = "Additional EKS managed node groups definition."
  type = object({
    name                 = optional(string, "single-node")
    bootstrap_extra_args = optional(string, "")
    ami = optional(object({
      name_prefix = optional(string, null)
      owner       = optional(string, null)

    }))
    instance_type            = optional(string, "m5.2xlarge")
    authorized_ssh_ip_ranges = optional(list(string), ["0.0.0.0/0"])
    labels                   = optional(map(string))
    taints = optional(list(object({
      key    = string
      value  = optional(string)
      effect = string
    })), [])
    volume = optional(object({
      size = optional(number, 1000)
      type = optional(string, "gp3")
    }), {})
  })

  default = {}
}


variable "ignore_tag_keys" {
  type        = list(string)
  description = "Tag keys to be ignored by the aws provider."
  default     = []
}
