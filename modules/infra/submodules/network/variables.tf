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
    use_pod_cidr        = Use additional pod CIDR range (ie 100.64.0.0/16) for pod networking.
    create_ecr_endpoint = Create the VPC Endpoint For ECR.
    create_s3_endpoint = Create the VPC Interface Endpoint For S3.
    create_ecr_endpoint = Create the VPC Endpoint For S3.
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
    use_pod_cidr        = optional(bool)
    create_ecr_endpoint = optional(bool, false)
    create_s3_endpoint  = optional(bool, true)
  })

  validation {
    condition = alltrue([
      for key, bits in coalesce(var.network.network_bits, {}) :
      key != "pod" ?
      bits > tonumber(regex("[^/]*$", var.network.cidrs.vpc)) : true
      if var.network.cidrs.vpc != null
    ])
    error_message = "Private and public network_bits values must be greater than the VPC CIDR's network bits (e.g., > 16 for '10.0.0.0/16')."
  }

  validation {
    condition = (
      var.network.use_pod_cidr != true || var.network.cidrs.pod == null || var.network.network_bits.pod == null ? true :
      var.network.network_bits.pod > tonumber(regex("[^/]*$", var.network.cidrs.pod))
    )
    error_message = "Pod network_bits value must be greater than the Pod CIDR's network bits (e.g., > 16 for '100.64.0.0/16')."
  }

  validation {
    condition = alltrue([
      for name, cidr in coalesce(var.network.cidrs, {}) :
      can(cidrhost(cidr, 0)) &&
      parseint(split("/", cidr)[1], 10) <= 32 && parseint(split("/", cidr)[1], 10) >= 8
    ])
    error_message = "Each of network.cidrs must be a valid CIDR block with a mask between /8 and /32."
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
      size       = string
      type       = string
      iops       = optional(number)
      throughput = optional(number, 500)
    })
  }))
}
