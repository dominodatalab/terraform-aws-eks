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
      addons = optional(list(string), ["kube-proxy", "coredns", "vpc-cni"])
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

variable "single_node" {
  description = "Additional EKS managed node groups definition."
  type = object({
    name                 = optional(string, "single-node")
    bootstrap_extra_args = optional(string, "")
    ami = optional(object({
      name_prefix = optional(string, null)
      owner       = optional(string, null)

    }))
    instance_type            = optional(string, "m6i.2xlarge")
    authorized_ssh_ip_ranges = optional(list(string), ["0.0.0.0/0"])
    labels                   = optional(map(string))
    taints = optional(list(object({
      key    = string
      value  = optional(string)
      effect = string
    })), [])
    volume = optional(object({
      size = optional(number, 200)
      type = optional(string, "gp3")
    }), {})
  })

  default = {}

  validation {
    condition     = var.single_node.ami.name_prefix != null ? length(var.single_node.ami.owner) > 0 : var.single_node.owner == null
    error_message = "var.single_node.owner is required if var.single_node.name_prefix is specified "
  }
}

variable "run_post_node_setup" {
  description = "Toggle installing addons and calico"
  type        = bool
  default     = true
}
