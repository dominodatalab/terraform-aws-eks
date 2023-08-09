variable "deploy_id" {
  type        = string
  description = "Domino Deployment ID"

  validation {
    condition     = can(regex("^[a-z-0-9]{3,32}$", var.deploy_id))
    error_message = "Argument deploy_id must: start with a letter, contain lowercase alphanumeric characters(can contain hyphens[-]) with length between 3 and 32 characters."
  }
}

variable "region" {
  type        = string
  description = "AWS region for the deployment"
  nullable    = false
  validation {
    condition     = can(regex("(us(-gov)?|ap|ca|cn|eu|sa|me|af|il)-(central|(north|south)?(east|west)?)-[0-9]", var.region))
    error_message = "The provided region must follow the format of AWS region names, e.g., us-west-2, us-gov-west-1."
  }
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
      pod     = The IPv4 CIDR block for the Pod subnets.
    }
    vpc_endpoint_services = [{
      name      = Name of the VPC Enpoint Service.
      ports     = List of ports exposing the VPC Enpoint Service. i.e [8080, 8081]
      cert_arn  = Certificate ARN used by the NLB associated for the given VPC Endpoint Service.
      private_dns = Private DNS for the VPC Enpoint Service.
    }]
    use_pod_cidr = Use additional pod CIDR range (ie 100.64.0.0/16) for pod networking.
  EOF

  type = object({
    vpc = optional(object({
      id = optional(string)
      subnets = optional(object({
        private = optional(list(string))
        public  = optional(list(string))
        pod     = optional(list(string))
      }))
    }))
    network_bits = optional(object({
      public  = optional(number)
      private = optional(number)
      pod     = optional(number)
      }
    ))
    cidrs = optional(object({
      vpc = optional(string)
      pod = optional(string)
    }))
    vpc_endpoint_services = optional(list(object({
      name        = optional(string)
      ports       = optional(list(number))
      cert_arn    = optional(string)
      private_dns = optional(string)
    })))
    use_pod_cidr = optional(bool)
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
}

variable "route53_hosted_zone_name" {
  type        = string
  description = "Hosted zone for External DNS zone."
  default     = null
}

variable "node_groups" {
  description = "EKS managed node groups definition."
  type = map(object({
    ami                   = string
    bootstrap_extra_args  = string
    instance_types        = list(string)
    spot                  = bool
    min_per_az            = number
    max_per_az            = number
    desired_per_az        = number
    availability_zone_ids = list(string)
    labels                = map(string)
    taints = list(object({
      key    = string
      value  = string
      effect = string
    }))
    tags          = map(string)
    instance_tags = map(string)
    gpu           = bool
    volume = object({
      size = string
      type = string
    })
  }))
}
