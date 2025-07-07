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
      private = optional(list(object({
        name      = string
        subnet_id = string
        az        = string
        az_id     = string
      })), [])
      pod = optional(list(object({
        name      = string
        subnet_id = string
        az        = string
        az_id     = string
      })), [])
    })
  })
}

variable "eks_info" {
  description = <<EOF
    cluster = {
      addons            = List of addons
      specs             = Cluster spes. {
        name                      = Cluster name.
        endpoint                  = Cluster endpont.
        kubernetes_network_config = Cluster k8s nw config.
      }
      version           = K8s version.
      arn               = EKS Cluster arn.
      security_group_id = EKS Cluster security group id.
      endpoint          = EKS Cluster API endpoint.
      roles             = Default IAM Roles associated with the EKS cluster. {
        name = string
        arn = string
      }
      custom_roles      = Custom IAM Roles associated with the EKS cluster. {
        rolearn  = string
        username = string
        groups   = list(string)
      }
      oidc = {
        arn = OIDC provider ARN.
        url = OIDC provider url.
      }
    }
    nodes = {
      security_group_id = EKS Nodes security group id.
      roles = IAM Roles associated with the EKS Nodes.{
        name = string
        arn  = string
      }
    }
    kubeconfig = Kubeconfig details.{
      path       = string
      extra_args = string
    }
  EOF
  type = object({
    k8s_pre_setup_sh_file = string
    cluster = object({
      addons = optional(list(string), ["kube-proxy", "coredns", "vpc-cni", "eks-pod-identity-agent"])
      vpc_cni = optional(object({
        prefix_delegation = optional(bool, false)
        annotate_pod_ip   = optional(bool, true)
      }))
      specs = object({
        name     = string
        endpoint = string
        kubernetes_network_config = object({
          elastic_load_balancing = object({
            enabled = bool
          })
          ip_family         = string
          service_ipv4_cidr = string
          service_ipv6_cidr = string
        })
        certificate_authority = list(map(any))
      })
      version           = string
      arn               = string
      security_group_id = string
      endpoint          = string
      roles = list(object({
        name = string
        arn  = string
      }))
      custom_roles = list(object({
        rolearn  = string
        username = string
        groups   = list(string)
      }))
      oidc = object({
        arn = string
        url = string
      })
    })
    nodes = object({
      security_group_id = string
      roles = list(object({
        name = string
        arn  = string
      }))
    })
    kubeconfig = object({
      path       = string
      extra_args = string
    })
  })
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
          use_bottlerocket           = optional(bool, false)
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
            })), [
            {
              key    = "ebs.csi.aws.com/agent-not-ready",
              value  = "true",
              effect = "NO_EXECUTE"
            }
          ])
          tags = optional(map(string), {})
          gpu  = optional(bool, null)
          volume = optional(object({
            size       = optional(number, 1000)
            type       = optional(string, "gp3")
            iops       = optional(number)
            throughput = optional(number, 500)
            }), {
            size       = 1000
            type       = "gp3"
            iops       = null
            throughput = 500
            }
          )
      }),
      platform = object(
        {
          ami                        = optional(string, null)
          bootstrap_extra_args       = optional(string, "")
          instance_types             = optional(list(string), ["m7i-flex.2xlarge"])
          spot                       = optional(bool, false)
          use_bottlerocket           = optional(bool, false)
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
            })), []
          )
          tags = optional(map(string), {})
          gpu  = optional(bool, null)
          volume = optional(object({
            size       = optional(number, 100)
            type       = optional(string, "gp3")
            iops       = optional(number)
            throughput = optional(number)
            }), {
            size       = 100
            type       = "gp3"
            iops       = null
            throughput = null
            }
          )
      }),
      gpu = object(
        {
          ami                        = optional(string, null)
          bootstrap_extra_args       = optional(string, "")
          instance_types             = optional(list(string), ["g5.2xlarge"])
          spot                       = optional(bool, false)
          use_bottlerocket           = optional(bool, false)
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
            },
            {
              key    = "ebs.csi.aws.com/agent-not-ready",
              value  = "true",
              effect = "NO_EXECUTE"
            }

          ])
          tags = optional(map(string), {})
          gpu  = optional(bool, null)
          volume = optional(object({
            size       = optional(number, 1000)
            type       = optional(string, "gp3")
            iops       = optional(number)
            throughput = optional(number, 500)
            }), {
            size       = 1000
            type       = "gp3"
            iops       = null
            throughput = 500
            }
          )
      })
  })
  default = { platform = { availability_zone_ids = [] }, compute = { availability_zone_ids = [] }, gpu = { availability_zone_ids = [] } }
}

variable "additional_node_groups" {
  description = "Additional EKS managed node groups definition."
  type = map(object({
    ami                        = optional(string, null)
    bootstrap_extra_args       = optional(string, "")
    instance_types             = list(string)
    spot                       = optional(bool, false)
    use_bottlerocket           = optional(bool, false)
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
      })), [
      {
        key    = "ebs.csi.aws.com/agent-not-ready",
        value  = "true",
        effect = "NO_EXECUTE"
      }
    ])
    tags   = optional(map(string), {})
    gpu    = optional(bool, null)
    neuron = optional(bool, null)
    volume = object({
      size       = string
      type       = string
      iops       = optional(number)
      throughput = optional(number, 500)
    })
  }))
  default = {}
}

variable "karpenter_node_groups" {
  description = "Node groups for karpenter."
  type = map(object({
    single_nodegroup           = optional(bool, false)
    ami                        = optional(string, null)
    bootstrap_extra_args       = optional(string, "")
    instance_types             = optional(list(string), ["m6a.large"])
    spot                       = optional(bool, false)
    use_bottlerocket           = optional(bool, false)
    min_per_az                 = optional(number, 1)
    max_per_az                 = optional(number, 3)
    max_unavailable_percentage = optional(number, 50)
    max_unavailable            = optional(number)
    desired_per_az             = optional(number, 1)
    availability_zone_ids      = list(string)
    labels = optional(map(string), {
      "dominodatalab.com/node-pool" = "karpenter"
    })
    taints = optional(list(object({
      key    = string
      value  = optional(string)
      effect = string
    })), [])
    tags = optional(map(string), {})
    gpu  = optional(bool, null)
    volume = optional(object({
      size       = optional(string, "50")
      type       = optional(string, "gp3")
      iops       = optional(number)
      throughput = optional(number, 500)
    }), {})
  }))
  default = null
}

variable "tags" {
  type        = map(string)
  description = "Deployment tags."
  default     = {}
}

variable "ignore_tags" {
  type        = list(string)
  description = "Tag keys to be ignored by the aws provider."
  default     = []
}

variable "region" {
  type        = string
  description = "AWS region for the deployment"
  nullable    = false
  validation {
    condition     = can(regex("(us(-gov)?|ap|ca|cn|eu|sa|me|af)-(central|(north|south)?(east|west)?)-[0-9]", var.region))
    error_message = "The provided region must follow the format of AWS region names, e.g., us-west-2, us-gov-west-1."
  }
}


variable "kms_info" {
  description = <<EOF
    key_id  = KMS key id.
    key_arn = KMS key arn.
    enabled = KMS key is enabled
  EOF
  type = object({
    key_id  = string
    key_arn = string
    enabled = bool
  })
}

variable "use_fips_endpoint" {
  description = "Use aws FIPS endpoints"
  type        = bool
  default     = false
}
