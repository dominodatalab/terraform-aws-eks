variable "deploy_id" {
  type        = string
  description = "Domino Deployment ID"
  default     = ""

  validation {
    condition     = can(regex("^[a-z-0-9]{3,32}$", var.deploy_id))
    error_message = "Argument deploy_id must: start with a letter, contain lowercase alphanumeric characters(can contain hyphens[-]) with length between 3 and 32 characters."
  }
}

variable "region" {
  type        = string
  description = "AWS region for the deployment"
}

## This is an object in order to be used as a conditional in count, due to https://github.com/hashicorp/terraform/issues/26755
variable "flow_log_bucket_arn" {
  type        = object({ arn = string })
  description = "Bucket for vpc flow logging"
  default     = null
}

variable "add_eks_elb_tags" {
  type        = bool
  description = "Toggle k8s cluster tag on subnet"
  default     = true
}

variable "network" {
  description = <<EOF
    vpc = {
      id = Existing vpc id, it will bypass creation by this module.
      subnets = {
        private = Existing private subnets.
        public  = Existing public subnets.
        pod     = Existing pod subnets.
      }), {})
    }), {})
    network_bits = {
      public  = Number of network bits to allocate to the public subnet. i.e /27 -> 32 IPs.
      private = Number of network bits to allocate to the private subnet. i.e /19 -> 8,192 IPs.
      pod     = Number of network bits to allocate to the private subnet. i.e /19 -> 8,192 IPs.
    }
    cidrs = {
      vpc     = The IPv4 CIDR block for the VPC.
      public  = Number of network bits to allocate to the private subnet. i.e /19 -> 8,192 IPs.
      private = Number of network bits to allocate to the private subnet. i.e /19 -> 8,192 IPs.
      pod     = The IPv4 CIDR block for the Pod subnets.
    }
    use_pod_cidr = Use additional pod CIDR range (ie 100.64.0.0/16) for pod/service networking.
  EOF

  type = object({
    vpc = optional(object({
      id = optional(string, null)
      subnets = optional(object({
        private = optional(list(string), [])
        public  = optional(list(string), [])
        pod     = optional(list(string), [])
      }), {})
    }), {})
    network_bits = optional(object({
      public  = optional(number, 27)
      private = optional(number, 19)
      pod     = optional(number, 19)
      }
    ), {})
    cidrs = optional(object({
      vpc = optional(string, "10.0.0.0/16")
      pod = optional(string, "100.64.0.0/16")
    }), {})
    use_pod_cidr = optional(bool, true)
  })

  validation {
    condition = alltrue([for name, cidr in var.network.cidrs : try(cidrhost(cidr, 0), false) == regex("^(.*)/", cidr)[0] &&
    try(cidrnetmask(cidr), false) == "255.255.0.0"])
    error_message = "Each of network.cidrs must be a valid CIDR block."
  }

  validation {
    condition     = var.network.vpc.id != null ? var.network.vpc.subnets.private != null && length(var.network.vpc.subnets.private) >= 2 : true
    error_message = "Must provide 2 or more private subnets(EKS requirement), when providing a VPC."
  }

  validation {
    condition     = var.network.vpc.id == null ? length(var.network.vpc.subnets.private) == 0 : true
    error_message = "Must provide a vpc_id when providing private_subnets."
  }

  validation {
    condition     = var.network.vpc.id == null ? length(var.network.vpc.subnets.public) == 0 : true
    error_message = "Must provide a vpc_id when providing public_subnets."
  }

  validation {
    condition     = var.network.vpc.id == null ? length(var.network.vpc.subnets.pod) == 0 : true
    error_message = "Must provide a vpc_id when providing pod_subnets."
  }
  default = {}
}

variable "node_groups" {
  description = "EKS managed node groups definition."
  type = map(object({
    ami                   = optional(string, null)
    bootstrap_extra_args  = optional(string, "")
    instance_types        = list(string)
    spot                  = optional(bool, false)
    min_per_az            = number
    max_per_az            = number
    desired_per_az        = number
    availability_zone_ids = list(string)
    labels                = map(string)
    taints                = optional(list(object({ key = string, value = optional(string), effect = string })), [])
    tags                  = optional(map(string), {})
    instance_tags         = optional(map(string), {})
    gpu                   = optional(bool, false)
    volume = object({
      size = string
      type = string
    })
  }))
  default = {}
}

### Moved

# variable "availability_zone_ids" {
#   type        = list(string)
#   description = "List of availability zone IDs where the subnets will be created"
#   validation {
#     condition = (
#       length(compact(distinct(local.az_ids))) == length(local.az_ids)
#     )
#     error_message = "Argument availability_zones_ids must not contain any duplicate/empty values."
#   }
# }

# variable "public_cidrs" {
#   type        = list(string)
#   description = "list of cidrs for the public subnets"
# }

# variable "private_cidrs" {
#   type        = list(string)
#   description = "list of cidrs for the private subnets"
# }

# variable "pod_cidrs" {
#   type        = list(string)
#   description = "list of cidrs for the pod subnets"
# }

# variable "cidr" {
#   type        = string
#   default     = "10.0.0.0/16"
#   description = "The IPv4 CIDR block for the VPC."
#   validation {
#     condition = (
#       try(cidrhost(var.network.cidrs.vpc, 0), null) == regex("^(.*)/", var.network.cidrs.vpc)[0] &&
#       try(cidrnetmask(var.network.cidrs.vpc), null) == "255.255.0.0"
#     )
#     error_message = "Argument cidr must be a valid CIDR block."
#   }
# }

# variable "pod_cidr" {
#   type        = string
#   default     = "100.64.0.0/16"
#   description = "The IPv4 CIDR block for the VPC."
#   validation {
#     condition = (
#       try(cidrhost(var.network.cidrs.pod, 0), null) == regex("^(.*)/", var.network.cidrs.pod)[0] &&
#       try(cidrnetmask(var.network.cidrs.pod), null) == "255.255.0.0"
#     )
#     error_message = "Argument cidr must be a valid CIDR block."
#   }
# }

# variable "use_pod_cidr" {
#   type        = bool
#   description = "Use additional pod CIDR range (ie 100.64.0.0/16) for pod/service networking"
#   default     = true
# }
