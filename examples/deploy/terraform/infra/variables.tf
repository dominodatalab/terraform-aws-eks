variable "deploy_id" {
  description = "Domino Deployment ID."
  type        = string
}

variable "region" {
  description = "AWS region for the deployment"
  type        = string
}

variable "tags" {
  description = "Deployment tags."
  type        = map(string)
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
          taints = optional(list(object({
            key    = string
            value  = optional(string)
            effect = string
          })), [])
          tags = optional(map(string), {})
          gpu  = optional(bool, null)
          volume = optional(object({
            size = optional(number, 1000)
            type = optional(string, "gp3")
            }), {
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
          taints = optional(list(object({
            key    = string
            value  = optional(string)
            effect = string
          })), [])
          tags = optional(map(string), {})
          gpu  = optional(bool, null)
          volume = optional(object({
            size = optional(number, 100)
            type = optional(string, "gp3")
            }), {
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
          taints = optional(list(object({
            key    = string
            value  = optional(string)
            effect = string
            })), [{
            key    = "nvidia.com/gpu"
            value  = "true"
            effect = "NO_SCHEDULE"
            }
          ])
          tags = optional(map(string))
          gpu  = optional(bool)
          volume = optional(object({
            size = optional(number)
            type = optional(string)
          }))
      })
  })
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
    tags = optional(map(string))
    gpu  = optional(bool)
    volume = object({
      size = string
      type = string
    })
  }))

  default = {}
}

variable "kms" {
  description = <<EOF
    enabled = Toggle,if set use either the specified KMS key_id or a Domino-generated one.
    key_id  = optional(string, null)
  EOF

  type = object({
    enabled = optional(bool)
    key_id  = optional(string)
  })
}


variable "eks" {
  description = <<EOF
    k8s_version = EKS cluster k8s version.
    kubeconfig = {
      extra_args = Optional extra args when generating kubeconfig.
      path       = Fully qualified path name to write the kubeconfig file.
    }
    public_access = {
      enabled = Enable EKS API public endpoint.
      cidrs   = List of CIDR ranges permitted for accessing the EKS public endpoint.
    }
    "Custom role maps for aws auth configmap
    custom_role_maps = {
      rolearn  = string
      username = string
      groups   = list(string)
    }
    master_role_names  = IAM role names to be added as masters in eks.
    cluster_addons     = EKS cluster addons. vpc-cni is installed separately.
    vpc_cni            = Configuration for AWS VPC CNI
    ssm_log_group_name = CloudWatch log group to send the SSM session logs to.
    identity_providers = Configuration for IDP(Identity Provider).
  }
  EOF

  type = object({
    k8s_version = optional(string)
    kubeconfig = optional(object({
      extra_args = optional(string)
      path       = optional(string)
    }), {})
    public_access = optional(object({
      enabled = optional(bool)
      cidrs   = optional(list(string))
    }), {})
    custom_role_maps = optional(list(object({
      rolearn  = string
      username = string
      groups   = list(string)
    })))
    master_role_names  = optional(list(string))
    cluster_addons     = optional(list(string))
    ssm_log_group_name = optional(string)
    vpc_cni = optional(object({
      prefix_delegation = optional(bool)
    }))
    identity_providers = optional(list(object({
      client_id                     = string
      groups_claim                  = optional(string)
      groups_prefix                 = optional(string)
      identity_provider_config_name = string
      issuer_url                    = optional(string)
      required_claims               = optional(string)
      username_claim                = optional(string)
      username_prefix               = optional(string)
    })))
  })

  default = {}
}

variable "ssh_pvt_key_path" {
  description = "SSH private key filepath."
  type        = string
}

variable "route53_hosted_zone_name" {
  description = "Optional hosted zone for External DNS zone."
  type        = string
  default     = null
}

variable "bastion" {
  description = <<EOF
    enabled                  = Create bastion host.
    ami                      = Ami id. Defaults to latest 'amazon_linux_2' ami.
    instance_type            = Instance type.
    authorized_ssh_ip_ranges = List of CIDR ranges permitted for the bastion ssh access.
    username                 = Bastion user.
    install_binaries         = Toggle to install required Domino binaries in the bastion.
  EOF

  type = object({
    enabled                  = optional(bool)
    ami_id                   = optional(string)
    instance_type            = optional(string)
    authorized_ssh_ip_ranges = optional(list(string))
    username                 = optional(string)
    install_binaries         = optional(bool)
  })
}
