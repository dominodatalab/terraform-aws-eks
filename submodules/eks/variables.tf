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

variable "network_info" {
  description = <<EOF
    id = VPC ID.
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
      pod = List of pod Subnets.
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
      private = list(object({
        name      = string
        subnet_id = string
        az        = string
        az_id     = string
      }))
      pod = list(object({
        name      = string
        subnet_id = string
        az        = string
        az_id     = string
      }))
    })
  })

  validation {
    condition     = length(var.network_info.subnets.private) >= 2
    error_message = "EKS deployment needs at least 2 subnets. https://docs.aws.amazon.com/eks/latest/userguide/network_reqs.html."
  }
  validation {
    condition     = length(var.network_info.subnets.pod) != 1
    error_message = "EKS deployment needs at least 2 subnets. https://docs.aws.amazon.com/eks/latest/userguide/network_reqs.html."
  }
}


variable "node_iam_policies" {
  description = "Additional IAM Policy Arns for Nodes"
  type        = list(string)
}

variable "efs_security_group" {
  description = "Security Group ID for EFS"
  type        = string
}

variable "bastion_info" {
  description = <<EOF
    user                = Bastion username.
    public_ip           = Bastion public ip.
    security_group_id   = Bastion sg id.
    ssh_bastion_command = Command to ssh onto bastion.
  EOF
  type = object({
    user                = string
    public_ip           = string
    security_group_id   = string
    ssh_bastion_command = string
  })
  default = null
}

variable "secrets_kms_key" {
  type        = string
  description = "if set, use specified key for the EKS cluster secrets"
  default     = null
}

variable "node_groups_kms_key" {
  type        = string
  description = "if set, use specified key for the EKS node groups"
  default     = null
}


variable "eks" {
  description = <<EOF
    k8s_version = EKS cluster k8s version.
    kubeconfig = {
      extra_args = Optional extra args when generating kubeconfig.
      path       = Fully qualified path name to write the kubeconfig file. Defaults to '<current working directory>/kubeconfig'
    }
    public_access = {
      enabled = Enable EKS API public endpoint.
      cidrs   = List of CIDR ranges permitted for accessing the EKS public endpoint.
    }
    Custom role maps for aws auth configmap
    custom_role_maps = {
      rolearn = string
      username = string
      groups = list(string)
    }
    master_role_names = IAM role names to be added as masters in eks.
    cluster_addons = EKS cluster addons. vpc-cni is installed separately.

  EOF
  type = object({
    k8s_version = optional(string, "1.25")
    kubeconfig = optional(object({
      extra_args = optional(string, "")
      path       = optional(string)
    }), {})
    public_access = optional(object({
      enabled = optional(bool, false)
      cidrs   = optional(list(string), [])
    }), {})
    custom_role_maps = optional(list(object({
      rolearn  = string
      username = string
      groups   = list(string)
    })), [])
    master_role_names = optional(list(string), [])
    cluster_addons    = optional(list(string), [])
  })

  validation {
    condition     = var.eks.public_access.enabled ? length(var.eks.public_access.cidrs) > 0 : true
    error_message = "eks.public_access.cidrs must be configured when public access is enabled"
  }

  validation {
    condition = !var.eks.public_access.enabled ? true : alltrue([
      for cidr in var.eks.public_access.cidrs :
      try(cidrhost(cidr, 0), null) == regex("^(.*)/", cidr)[0] &&
      try(cidrnetmask(cidr), null) != null
    ])
    error_message = "All elements in eks.public_access.cidrs list must be valid CIDR blocks"
  }

  default = {}
}


variable "ssh_key" {
  description = <<EOF
    path          = SSH private key filepath.
    key_pair_name = AWS key_pair name.
  EOF
  type = object({
    path          = string
    key_pair_name = string
  })
}



## Moved


# variable "eks_public_access" {
#   type = object({
#     enabled = optional(bool, false)
#     cidrs   = optional(list(string), [])
#   })
#   description = "EKS API endpoint public access configuration"
#   nullable    = false
#   default     = { enabled = false }

#   validation {
#     condition     = var.eks.public_access.enabled ? length(var.eks.public_access.cidrs) > 0 : true
#     error_message = "eks_public_access.cidrs must be configured when public access is enabled"
#   }

#   validation {
#     condition = !var.eks.public_access.enabled ? true : alltrue([
#       for cidr in var.eks.public_access.cidrs :
#       try(cidrhost(cidr, 0), null) == regex("^(.*)/", cidr)[0] &&
#       try(cidrnetmask(cidr), null) != null
#     ])
#     error_message = "All elements in eks_public_access.cidrs list must be valid CIDR blocks"
#   }
# }


# variable "eks_custom_role_maps" {
#   type        = list(object({ rolearn = string, username = string, groups = list(string) }))
#   description = "Custom role maps for aws auth configmap"
#   default     = []
# }


# variable "eks_master_role_names" {
#   type        = list(string)
#   description = "IAM role names to be added as masters in eks"
#   default     = []
# }


# variable "k8s_version" {
#   type        = string
#   description = "EKS cluster k8s version."
# }
# variable "update_kubeconfig_extra_args" {
#   type        = string
#   description = "Optional extra args when generating kubeconfig"
#   default     = ""
# }


# variable "eks_cluster_addons" {
#   type        = list(string)
#   description = "EKS cluster addons. vpc-cni is installed separately."
#   default     = ["kube-proxy", "coredns"]
# }

##

# variable "ssh_key_pair_name" {
#   type        = string
#   description = "SSH key pair name."
# }

# variable "ssh_pvt_key_path" {
#   type        = string
#   description = "Path to SSH private key"
#   default     = ""
# }

###

# variable "private_subnets" {
#   description = "List of Private subnets IDs and AZ"
#   type        = list(object({ subnet_id = string, az = string, az_id = string }))
#   validation {
#     condition     = length(var.network_info.subnets.private) >= 2
#     error_message = "EKS deployment needs at least 2 subnets. https://docs.aws.amazon.com/eks/latest/userguide/network_reqs.html."
#   }
# }

# variable "pod_subnets" {
#   description = "List of POD subnets IDs and AZ"
#   type        = list(object({ subnet_id = string, az = string, az_id = string }))
#   validation {
#     condition     = length(var.network_info.subnets.pod) != 1
#     error_message = "EKS deployment needs at least 2 subnets. https://docs.aws.amazon.com/eks/latest/userguide/network_reqs.html."
#   }
# }

# variable "vpc_id" {
#   type        = string
#   description = "VPC ID."
# }



# variable "bastion_user" {
#   type        = string
#   description = "Username for bastion instance"
#   default     = ""
# }

# variable "bastion_public_ip" {
#   type        = string
#   description = "Public IP of bastion instance"
#   default     = null
# }


# variable "kubeconfig_path" {
#   type        = string
#   description = "Kubeconfig file path."
#   default     = "kubeconfig"
# }


# variable "bastion_security_group_id" {
#   type        = string
#   description = "Bastion security group id."
#   default     = null
# }


# variable "create_bastion_sg" {
#   description = "Create bastion access rules toggle."
#   type        = bool
#   default     = false
# }
