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
    vpc_cni = Configuration for AWS VPC CNI
    ssm_log_group_name = "CloudWatch log group to send the SSM session logs to."
    identity_providers = "Configuration for IDP(Identity Provider)."
  }
  EOF

  type = object({
    k8s_version = optional(string, "1.27")
    kubeconfig = optional(object({
      extra_args = optional(string, "")
      path       = optional(string, null)
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
    master_role_names  = optional(list(string), [])
    cluster_addons     = optional(list(string), ["kube-proxy", "coredns"])
    ssm_log_group_name = optional(string, "session-manager")
    vpc_cni = optional(object({
      prefix_delegation = optional(bool)
    }))
    identity_providers = optional(list(object({
      client_id                     = string
      groups_claim                  = optional(string, null)
      groups_prefix                 = optional(string, null)
      identity_provider_config_name = string
      issuer_url                    = optional(string, null)
      required_claims               = optional(string, null)
      username_claim                = optional(string, null)
      username_prefix               = optional(string, null)
    })), [])
  })

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

variable "create_eks_role_arn" {
  description = "Role arn to assume during the EKS cluster creation."
  type        = string
}

variable "tags" {
  type        = map(string)
  description = "Deployment tags."
  default     = {}
}

variable "vpc_endpoint_services" {
  description = <<EOF
    [{
      name      = Name of the VPC Endpoint Service.
      ports     = List of ports exposing the VPC Endpoint Service. i.e [8080, 8081]
      cert_arn  = Certificate ARN used by the NLB associated for the given VPC Endpoint Service.
      private_dns = Private DNS for the VPC Endpoint Service.
    }]
  EOF

  type = list(object({
    name        = optional(string)
    ports       = optional(list(number))
    cert_arn    = optional(string)
    private_dns = optional(string)
  }))

  default = []
}

variable "route53_hosted_zone_name" {
  type        = string
  description = "Hosted zone for External DNS zone."
  default     = null
}

variable "monitoring_bucket" {
  type        = string
  description = "Monitoring bucket"
  nullable    = false
}

variable "enable_private_link" {
  type        = bool
  description = "Enable Private Link connections"
  default     = false
}
