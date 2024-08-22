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

variable "eks_info" {
  description = <<EOF
    cluster = {
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
    calico = {
      version = Configuration the version for Calico
      image_registry = Configure the image registry for Calico
    }
  EOF
  type = object({
    cluster = object({
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
      nodes_master      = bool
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
    calico = object({
      version        = string
      image_registry = string
    })
  })
}

variable "use_fips_endpoint" {
  description = "Use aws FIPS endpoints"
  type        = bool
  default     = false
}

variable "netapp" {
  description = "Configuration for NetApp"
  type = object({
    astra_trident_operator_role = optional(string, null)
    svm = optional(object({
      id            = optional(string, null)
      management_ip = optional(string, null)
      nfs_ip        = optional(string, null)
    }), null)
    filesystem = optional(object({
      id = optional(string, null)
    }), null)
  })
  default = null
}
