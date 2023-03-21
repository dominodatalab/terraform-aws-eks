variable "region" {
  type        = string
  description = "AWS region for the deployment"
}

variable "deploy_id" {
  type        = string
  description = "Domino Deployment ID."
  default     = "domino-eks"
  nullable    = false

  validation {
    condition     = length(var.deploy_id) >= 3 && length(var.deploy_id) <= 32 && can(regex("^[a-z]([-a-z0-9]*[a-z0-9])$", var.deploy_id))
    error_message = <<EOT
      Variable deploy_id must:
      1. Length must be between 3 and 32 characters.
      2. Start with a letter.
      3. End with a letter or digit.
      4. Contain lowercase Alphanumeric characters and hyphens.
    EOT
  }
}

variable "route53_hosted_zone_name" {
  type        = string
  description = "Optional hosted zone for External DNSone."
  default     = null
}

variable "tags" {
  type        = map(string)
  description = "Deployment tags."
  default     = {}
}

variable "ssh_pvt_key_path" {
  type        = string
  description = "SSH private key filepath."
  validation {
    condition     = fileexists(var.ssh_pvt_key_path)
    error_message = "Private key does not exist. Please provide the right path or generate a key with the following command: ssh-keygen -q -P '' -t rsa -b 4096 -m PEM -f domino.pem"
  }
}

variable "eks" {
  description = <<EOF
    k8s_version = "EKS cluster k8s version."
    kubeconfig = {
      extra_args = "Optional extra args when generating kubeconfig."
      path       = "Fully qualified path name to write the kubeconfig file."
    }
    public_access = {
      enabled = "Enable EKS API public endpoint."
      cidrs   = "List of CIDR ranges permitted for accessing the EKS public endpoint."
    }
    "Custom role maps for aws auth configmap"
    custom_role_maps = {
      rolearn = string
      username = string
      groups = list(string)
    }
    master_role_names = "IAM role names to be added as masters in eks."
    cluster_addons = "EKS cluster addons. vpc-cni is installed separately."
  EOF

  type = object({
    k8s_version = optional(string)
    kubeconfig = optional(object({
      extra_args = optional(string)
      path       = optional(string)
    }))
    public_access = optional(object({
      enabled = optional(bool)
      cidrs   = optional(list(string))
    }))
    custom_role_maps = optional(list(object({
      rolearn  = string
      username = string
      groups   = list(string)
    })))
    master_role_names = optional(list(string))
    cluster_addons    = optional(list(string))
  })


  default = {}
}

variable "default_node_groups" {
  description = "EKS managed node groups definition."
  type = object(
    {
      compute = object(
        {
          ami                   = optional(string, null)
          bootstrap_extra_args  = optional(string, "")
          instance_types        = optional(list(string), ["m5.2xlarge"])
          spot                  = optional(bool, false)
          min_per_az            = optional(number, 0)
          max_per_az            = optional(number, 10)
          desired_per_az        = optional(number, 0)
          availability_zone_ids = list(string)
          labels = optional(map(string), {
            "dominodatalab.com/node-pool" = "default"
          })
          taints = optional(list(object({ key = string, value = optional(string), effect = string })), [])
          tags   = optional(map(string), {})
          gpu    = optional(bool, null)
          volume = optional(object(
            {
              size = optional(number, 1000)
              type = optional(string, "gp3")
            }),
            {
              size = 1000
              type = "gp3"
            }
          )
      }),
      platform = object(
        {
          ami                   = optional(string, null)
          bootstrap_extra_args  = optional(string, "")
          instance_types        = optional(list(string), ["m5.2xlarge"])
          spot                  = optional(bool, false)
          min_per_az            = optional(number, 1)
          max_per_az            = optional(number, 10)
          desired_per_az        = optional(number, 1)
          availability_zone_ids = list(string)
          labels = optional(map(string), {
            "dominodatalab.com/node-pool" = "platform"
          })
          taints = optional(list(object({ key = string, value = optional(string), effect = string })), [])
          tags   = optional(map(string), {})
          gpu    = optional(bool, null)
          volume = optional(object(
            {
              size = optional(number, 100)
              type = optional(string, "gp3")
            }),
            {
              size = 100
              type = "gp3"
            }
          )
      }),
      gpu = object(
        {
          ami                   = optional(string, null)
          bootstrap_extra_args  = optional(string, "")
          instance_types        = optional(list(string), ["g4dn.xlarge"])
          spot                  = optional(bool, false)
          min_per_az            = optional(number, 0)
          max_per_az            = optional(number, 10)
          desired_per_az        = optional(number, 0)
          availability_zone_ids = list(string)
          labels = optional(map(string), {
            "dominodatalab.com/node-pool" = "default-gpu"
            "nvidia.com/gpu"              = true
          })
          taints = optional(list(object({ key = string, value = optional(string), effect = string })), [
            { key = "nvidia.com/gpu", value = "true", effect = "NO_SCHEDULE" }
          ])
          tags = optional(map(string), {})
          gpu  = optional(bool, null)
          volume = optional(object(
            {
              size = optional(number, 1000)
              type = optional(string, "gp3")
            }),
            {
              size = 1000
              type = "gp3"
            }
          )
      })
  })
}

variable "additional_node_groups" {
  description = "Additional EKS managed node groups definition."
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
    gpu                   = optional(bool, null)
    volume = object({
      size = string
      type = string
    })
  }))
  default = {}
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
      id = optional(string)
      subnets = optional(object({
        private = optional(list(string))
        public  = optional(list(string))
        pod     = optional(list(string))
      }), {})
    }), {})
    network_bits = optional(object({
      public  = optional(number)
      private = optional(number)
      pod     = optional(number)
      }
    ), {})
    cidrs = optional(object({
      vpc = optional(string)
      pod = optional(string)
    }), {})
    use_pod_cidr = optional(bool)
  })

  default = {}
}

variable "bastion" {
  description = <<EOF
    ami                      = Ami id. Defaults to latest 'amazon_linux_2' ami.
    instance_type            = "Instance type."
    authorized_ssh_ip_ranges = List of CIDR ranges permitted for the bastion ssh access.
    username                 = Bastion user.
    install_binaries         = Toggle to install required Domino binaries in the bastion.
  EOF
  type = object({
    ami_id                   = optional(string) # default will use the latest 'amazon_linux_2' ami
    instance_type            = optional(string)
    authorized_ssh_ip_ranges = optional(list(string))
    username                 = optional(string)
    install_binaries         = optional(bool)
  })
  default = {}
}


variable "storage" {
  description = <<EOF
    storage = {
      efs = {
        access_point_path = "Filesystem path for efs."
        backup_vault = {
          create        = "Create backup vault for EFS toggle."
          force_destroy = "Toggle to allow automatic destruction of all backups when destroying."
          backup = {
            schedule           = optional(string)
            cold_storage_after = "Move backup data to cold storage after this many days."
            delete_after       = "Delete backup data after this many days."
          }
        }
      }
      s3 = {
        force_destroy_on_deletion = "Toogle to allow recursive deletion of all objects in the s3 buckets. if 'false' terraform will NOT be able to delete non-empty buckets"
      }
      ecr = {
        force_destroy_on_deletion = "Toogle to allow recursive deletion of all objects in the ECR repositories. if 'false' terraform will NOT be able to delete non-empty repositories"
      }
    }
  }
  EOF
  type = object({
    efs = optional(object({
      access_point_path = optional(string)
      backup_vault = optional(object({
        create        = optional(bool)
        force_destroy = optional(bool)
        backup = optional(object({
          schedule           = optional(string)
          cold_storage_after = optional(number)
          delete_after       = optional(number)
        }))
      }))
    }))
    s3 = optional(object({
      force_destroy_on_deletion = optional(bool)
    }))
    ecr = optional(object({
      force_destroy_on_deletion = optional(bool)
    }))
  })
  default = {}
}

variable "kms" {
  description = <<EOF
    enabled = "Toggle,if set use either the specified KMS key_id or a Domino-generated one"
    key_id  = optional(string, null)
  EOF
  type = object({
    enabled = optional(bool, false)
    key_id  = optional(string, null)
  })

  validation {
    condition     = var.kms.key_id == null ? true : length(var.kms.key_id) > 0
    error_message = "KMS key ID must be null or set to a non-empty string"
  }

  validation {
    condition     = var.kms.key_id != null ? var.kms.enabled : true
    error_message = "var.kms.enabled must be true if var.kms.key_id is provided."
  }

  default = {}
}

#####

### Moved

# variable "s3_force_destroy_on_deletion" {
#   description = "Toogle to allow recursive deletion of all objects in the s3 buckets. if 'false' terraform will NOT be able to delete non-empty buckets"
#   type        = bool
#   default     = false
# }

# variable "ecr_force_destroy_on_deletion" {
#   description = "Toogle to allow recursive deletion of all objects in the ECR repositories. if 'false' terraform will NOT be able to delete non-empty repositories"
#   type        = bool
#   default     = false
# }

# variable "efs_access_point_path" {
#   type        = string
#   description = "Filesystem path for efs."
#   default     = "/domino"
# }

# variable "create_efs_backup_vault" {
#   description = "Create backup vault for EFS toggle."
#   type        = bool
#   default     = true
# }

# variable "efs_backup_vault_force_destroy" {
#   description = "Toggle to allow automatic destruction of all backups when destroying."
#   type        = bool
#   default     = false
# }

# variable "efs_backup_schedule" {
#   type        = string
#   description = "Cron-style schedule for EFS backup vault (default: once a day at 12pm)"
#   default     = "0 12 * * ? *"
# }

# variable "efs_backup_cold_storage_after" {
#   type        = number
#   description = "Move backup data to cold storage after this many days"
#   default     = 35
# }

# variable "efs_backup_delete_after" {
#   type        = number
#   description = "Delete backup data after this many days"
#   default     = 125
# }

## 2

# variable "public_cidr_network_bits" {
#   type        = number
#   description = "Number of network bits to allocate to the public subnet. i.e /27 -> 32 IPs."
#   default     = 27
# }

# variable "private_cidr_network_bits" {
#   type        = number
#   description = "Number of network bits to allocate to the private subnet. i.e /19 -> 8,192 IPs."
#   default     = 19
# }

# variable "pod_cidr_network_bits" {
#   type        = number
#   description = "Number of network bits to allocate to the private subnet. i.e /19 -> 8,192 IPs."
#   default     = 19
# }
# variable "cidr" {
#   type        = string
#   default     = "10.0.0.0/16"
#   description = "The IPv4 CIDR block for the VPC."
#   validation {
#     condition = (
#       try(cidrhost(var.cidr, 0), null) == regex("^(.*)/", var.cidr)[0] &&
#       try(cidrnetmask(var.cidr), null) == "255.255.0.0"
#     )
#     error_message = "Argument base_cidr_block must be a valid CIDR block."
#   }
# }

# variable "pod_cidr" {
#   type        = string
#   default     = "100.64.0.0/16"
#   description = "The IPv4 CIDR block for the VPC."
#   validation {
#     condition = (
#       try(cidrhost(var.pod_cidr, 0), null) == regex("^(.*)/", var.pod_cidr)[0] &&
#       try(cidrnetmask(var.pod_cidr), null) == "255.255.0.0"
#     )
#     error_message = "Argument base_cidr_block must be a valid CIDR block."
#   }
# }

# variable "use_pod_cidr" {
#   type        = bool
#   description = "Use additional pod CIDR range (ie 100.64.0.0/16) for pod/service networking"
#   default     = true
# }



###

# variable "vpc_id" {
#   type        = string
#   description = "Optional VPC ID, it will bypass creation of such, public_subnets and private_subnets are also required."
#   default     = null
# }

# variable "public_subnets" {
#   type        = list(string)
#   description = "Optional list of public subnet ids"
#   default     = null
# }

# variable "private_subnets" {
#   type        = list(string)
#   description = "Optional list of private subnet ids"
#   default     = null
# }

# variable "pod_subnets" {
#   type        = list(string)
#   description = "Optional list of pod subnet ids"
#   default     = null
# }

###

# variable "k8s_version" {
#   type        = string
#   description = "EKS cluster k8s version."
#   default     = "1.25"
# }

# variable "update_kubeconfig_extra_args" {
#   type        = string
#   description = "Optional extra args when generating kubeconfig"
#   default     = ""
# }

# variable "eks_master_role_names" {
#   type        = list(string)
#   description = "IAM role names to be added as masters in eks."
#   default     = []
# }

# variable "kubeconfig_path" {
#   description = "fully qualified path name to write the kubeconfig file"
#   type        = string
#   default     = ""
# }


# variable "eks_custom_role_maps" {
#   type        = list(object({ rolearn = string, username = string, groups = list(string) }))
#   description = "Custom role maps for aws auth configmap"
#   default     = []
# }

# variable "eks_public_access" {
#   type = object({
#     enabled = optional(bool, false)
#     cidrs   = optional(list(string), [])
#   })
#   description = "EKS API endpoint public access configuration"
#   default     = null
# }


###

# variable "use_kms" {
#   description = "if set, use either the specified KMS key or a Domino-generated one"
#   type        = bool
#   default     = false
# }


# variable "kms_key_id" {
#   description = "if use_kms is set, use the specified KMS key"
#   type        = string
#   default     = null
#   validation {
#     condition     = var.kms_key_id == null ? true : length(var.kms_key_id) > 0
#     error_message = "KMS key ID must be null or set to a non-empty string"
#   }
# }


###

# variable "my_vpc" {
#   description = <<EOF
#     vpc_id          = VPC ID, it will bypass creation of such, public_subnets and private_subnets are also required.
#     private_subnets = List of private subnet ids.
#     public_subnets  = List of public subnet ids.
#     pod_subnets     = List of pod subnet ids.
#   EOF
#   type = object({
#     vpc_id          = optional(string, null)
#     private_subnets = optional(list(string), [])
#     public_subnets  = optional(list(string), [])
#     pod_subnets     = optional(list(string), [])
#   })

#   validation {
#     condition     = var.my_vpc.vpc_id != null ? var.my_vpc.private_subnets != null && length(var.my_vpc.private_subnets) >= 2 : true
#     error_message = "Must provide 2 or more private subnets, when providing a VPC."
#   }

#   validation {
#     condition     = var.my_vpc.vpc_id == null ? length(var.my_vpc.private_subnets) == 0 : true
#     error_message = "Must provide a vpc_id when providing private_subnets."
#   }

#   validation {
#     condition     = var.my_vpc.vpc_id == null ? length(var.my_vpc.public_subnets) == 0 : true
#     error_message = "Must provide a vpc_id when providing public_subnets."
#   }

#   validation {
#     condition     = var.my_vpc.vpc_id == null ? length(var.my_vpc.pod_subnets) == 0 : true
#     error_message = "Must provide a vpc_id when providing pod_subnets."
#   }
#   default = {}
# }
