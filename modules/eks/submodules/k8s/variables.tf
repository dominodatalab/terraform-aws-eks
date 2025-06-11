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

variable "ssh_extra_args" {
  description = "Extra arguments passed to SSH"
  type        = string
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

variable "cluster_name" {
  description = "Name of EKS clsuter"
  type        = string
  default     = ""
}

variable "karpenter" {
  description = <<EOF
    karpenter = {
      enabled = Toggle installation of Karpenter.
      namespace = Namespace to install Karpenter.
      version = Configure the version for Karpenter.
      delete_instances_on_destroy = Toggle to delete Karpenter instances on destroy.
    }
  EOF
  type = object({
    enabled                     = bool
    delete_instances_on_destroy = bool
    namespace                   = string
    version                     = string
  })
}

variable "region" {
  description = "Region of the EKS cluster"
  type        = string
}
