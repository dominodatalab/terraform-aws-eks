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
    condition     = can(regex("^([a-z]{2}-[a-z]+-[0-9])$", var.region))
    error_message = "The provided region must follow the format of AWS region names, e.g., us-west-2."
  }
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

variable "kms_info" {
  description = <<EOF
    key_id  = KMS key id.
    key_arn = KMS key arn.
  EOF
  type = object({
    key_id  = string
    key_arn = string
  })
  default = null
}

variable "ssm_log_group_name" {
  type        = string
  description = "CW log group to send the SSM session logs to"
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
    List of Custom role maps for aws auth configmap
    custom_role_maps = [{
      rolearn = string
      username = string
      groups = list(string)
    }]
    master_role_names = IAM role names to be added as masters in EKS.
    cluster_addons = EKS cluster addons. vpc-cni is installed separately.
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
