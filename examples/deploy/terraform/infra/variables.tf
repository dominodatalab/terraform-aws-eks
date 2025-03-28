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

variable "ignore_tags" {
  type        = list(string)
  description = "Tag keys to be ignored by the aws provider."
  default     = []
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
    use_pod_cidr = Use additional pod CIDR range (ie 100.64.0.0/16) for pod networking.
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

  default = {}
}

variable "default_node_groups" {
  description = "EKS managed node groups definition."
  type = object(
    {
      compute = object(
        {
          ami                        = optional(string, null)
          bootstrap_extra_args       = optional(string, "")
          instance_types             = optional(list(string), ["m6i.2xlarge"])
          spot                       = optional(bool, false)
          min_per_az                 = optional(number, 0)
          max_per_az                 = optional(number, 10)
          max_unavailable_percentage = optional(number, 50)
          max_unavailable            = optional(number, null)
          desired_per_az             = optional(number, 0)
          availability_zone_ids      = list(string)
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
          ami                        = optional(string, null)
          bootstrap_extra_args       = optional(string, "")
          instance_types             = optional(list(string), ["m7i-flex.2xlarge"])
          spot                       = optional(bool, false)
          min_per_az                 = optional(number, 1)
          max_per_az                 = optional(number, 10)
          max_unavailable_percentage = optional(number, null)
          max_unavailable            = optional(number, 1)
          desired_per_az             = optional(number, 1)
          availability_zone_ids      = list(string)
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
          ami                        = optional(string, null)
          bootstrap_extra_args       = optional(string, "")
          instance_types             = optional(list(string), ["g5.2xlarge"])
          spot                       = optional(bool, false)
          min_per_az                 = optional(number, 0)
          max_per_az                 = optional(number, 10)
          max_unavailable_percentage = optional(number, 50)
          max_unavailable            = optional(number, null)
          desired_per_az             = optional(number, 0)
          availability_zone_ids      = list(string)
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
    ami                        = optional(string)
    bootstrap_extra_args       = optional(string)
    instance_types             = list(string)
    spot                       = optional(bool)
    min_per_az                 = number
    max_per_az                 = number
    max_unavailable_percentage = optional(number, 50)
    max_unavailable            = optional(number)
    desired_per_az             = number
    availability_zone_ids      = list(string)
    labels                     = map(string)
    taints = optional(list(object({
      key    = string
      value  = optional(string)
      effect = string
    })))
    tags   = optional(map(string))
    gpu    = optional(bool)
    neuron = optional(bool)
    volume = object({
      size = string
      type = string
    })
  }))

  default = {}
}

variable "storage" {
  description = <<EOF
    storage = {
      filesystem_type = File system type(netapp|efs|none)
      efs = {
        access_point_path = Filesystem path for efs.
        backup_vault = {
          create        = Create backup vault for EFS toggle.
          force_destroy = Toggle to allow automatic destruction of all backups when destroying.
          backup = {
            schedule           = Cron-style schedule for EFS backup vault (default: once a day at 12pm).
            cold_storage_after = Move backup data to cold storage after this many days.
            delete_after       = Delete backup data after this many days.
          }
        }
      }
      netapp = {
        migrate_from_efs = {
          enabled =  When enabled, both EFS and NetApp resources will be provisioned simultaneously during the migration period.
          datasync = {
            enabled  = Toggle to enable AWS DataSync for automated data transfer from EFS to NetApp FSx.
            schedule = Cron-style schedule for the DataSync task, specifying how often the data transfer will occur (default: hourly).
            verify_mode = One of: POINT_IN_TIME_CONSISTENT, ONLY_FILES_TRANSFERRED, NONE.
          }
        }
        deployment_type = netapp ontap deployment type,('MULTI_AZ_1', 'MULTI_AZ_2', 'SINGLE_AZ_1', 'SINGLE_AZ_2')
        storage_capacity = Filesystem Storage capacity
        throughput_capacity = Filesystem throughput capacity
        automatic_backup_retention_days = How many days to keep backups
        daily_automatic_backup_start_time = Start time in 'HH:MM' format to initiate backups

        storage_capacity_autosizing = Options for the FXN automatic storage capacity increase, cloudformation template
          enabled                     = Enable automatic storage capacity increase.
          threshold                  = Used storage capacity threshold.
          percent_capacity_increase  = The percentage increase in storage capacity when used storage exceeds
                                       LowFreeDataStorageCapacityThreshold. Minimum increase is 10 %.
          notification_email_address = The email address for alarm notification.
        }
        volume = {
          create                     = Create a volume associated with the filesystem.
          name_suffix                = The suffix to name the volume
          storage_efficiency_enabled = Toggle storage_efficiency_enabled
          junction_path              = filesystem junction path
          size_in_megabytes          = The size of the volume
      }
      s3 = {
        force_destroy_on_deletion = Toogle to allow recursive deletion of all objects in the s3 buckets. if 'false' terraform will NOT be able to delete non-empty buckets.
      }
      ecr = {
        force_destroy_on_deletion = Toogle to allow recursive deletion of all objects in the ECR repositories. if 'false' terraform will NOT be able to delete non-empty repositories.
      }
      enable_remote_backup = Enable tagging required for cross-account backups
      costs_enabled = Determines whether to provision domino cost related infrastructures, ie, long term storage
    }
  }
  EOF
  type = object({
    filesystem_type = optional(string, "efs")
    efs = optional(object({
      access_point_path = optional(string, "/domino")
      backup_vault = optional(object({
        create        = optional(bool, true)
        force_destroy = optional(bool, true)
        backup = optional(object({
          schedule           = optional(string, "0 12 * * ? *")
          cold_storage_after = optional(number, 35)
          delete_after       = optional(number, 125)
        }), {})
      }), {})
    }), {})
    netapp = optional(object({
      migrate_from_efs = optional(object({
        enabled = optional(bool, false)
        datasync = optional(object({
          enabled     = optional(bool, false)
          target      = optional(string, "netapp")
          schedule    = optional(string, "cron(0 */4 * * ? *)")
          verify_mode = optional(string, "ONLY_FILES_TRANSFERRED")
        }), {})
      }), {})
      deployment_type                   = optional(string, "SINGLE_AZ_1")
      storage_capacity                  = optional(number, 1024)
      throughput_capacity               = optional(number, 128)
      automatic_backup_retention_days   = optional(number, 90)
      daily_automatic_backup_start_time = optional(string, "00:00")
      storage_capacity_autosizing = optional(object({
        enabled                    = optional(bool, false)
        threshold                  = optional(number, 70)
        percent_capacity_increase  = optional(number, 30)
        notification_email_address = optional(string, "")
      }), {})
      volume = optional(object({
        create                     = optional(bool, true)
        name_suffix                = optional(string, "domino_shared_storage")
        storage_efficiency_enabled = optional(bool, true)
        junction_path              = optional(string, "/domino")
        size_in_megabytes          = optional(number, 1099511)
      }), {})
    }), {})
    s3 = optional(object({
      create                    = optional(bool, true)
      force_destroy_on_deletion = optional(bool, true)
    }), {})
    ecr = optional(object({
      create                    = optional(bool, true)
      force_destroy_on_deletion = optional(bool, true)
    }), {}),
    enable_remote_backup = optional(bool, false)
    costs_enabled        = optional(bool, true)
  })

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
    run_k8s_setup = Toggle to run the k8s setup.
    service_ipv4_cidr = CIDR for EKS cluster kubernetes_network_config.
    creation_role_name = Name of the role to import.
    k8s_version = EKS cluster k8s version.
    nodes_master  Grants the nodes role system:master access. NOT recomended
    kubeconfig = {
      extra_args = Optional extra args when generating kubeconfig.
      path       = Fully qualified path name to write the kubeconfig file.
    }
    public_access = {
      enabled = Enable EKS API public endpoint.
      cidrs   = List of CIDR ranges permitted for accessing the EKS public endpoint.
    }
    Custom role maps for aws auth configmap
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
    run_k8s_setup      = optional(bool)
    service_ipv4_cidr  = optional(string)
    creation_role_name = optional(string, null)
    k8s_version        = optional(string)
    nodes_master       = optional(bool, false)
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
      annotate_pod_ip   = optional(bool)
    }))
    identity_providers = optional(list(object({
      client_id                     = string
      groups_claim                  = optional(string)
      groups_prefix                 = optional(string)
      identity_provider_config_name = string
      issuer_url                    = optional(string)
      required_claims               = optional(map(string))
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

variable "bastion" {
  description = <<EOF
    enabled                  = Create bastion host.
    ami                      = Ami id. Defaults to latest 'AL2023' ami.
    instance_type            = Instance type.
    authorized_ssh_ip_ranges = List of CIDR ranges permitted for the bastion ssh access.
    username                 = Bastion user.
    install_binaries         = Toggle to install required Domino binaries in the bastion.
  EOF

  type = object({
    enabled                  = optional(bool, true)
    ami_id                   = optional(string)
    instance_type            = optional(string)
    authorized_ssh_ip_ranges = optional(list(string))
    username                 = optional(string)
    install_binaries         = optional(bool)
  })
}


variable "domino_cur" {
  description = "Determines whether to provision domino cost related infrastructures, ie, long term storage"
  type = object({
    provision_cost_usage_report = optional(bool, false)
  })

  default = {}
}

variable "use_fips_endpoint" {
  description = "Use aws FIPS endpoints"
  type        = bool
  default     = false
}
