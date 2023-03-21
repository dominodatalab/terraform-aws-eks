variable "kubeconfig_path" {
  type        = string
  description = "Kubeconfig filename."
  default     = "kubeconfig"
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

variable "eks_cluster_arn" {
  type        = string
  description = "ARN of the EKS cluster"
}

variable "eks_node_role_arns" {
  type        = list(string)
  description = "Roles arns for EKS nodes to be added to aws-auth for api auth."
}

variable "eks_master_role_arns" {
  type        = list(string)
  description = "IAM role arns to be added as masters in eks."
  default     = []
}

variable "k8s_tunnel_port" {
  type        = string
  description = "K8s ssh tunnel port"
  default     = "1080"
}

variable "calico_version" {
  type        = string
  description = "Calico operator version."
  default     = "v3.25.0"
}

variable "security_group_id" {
  type        = string
  description = "Security group id for eks cluster."
}


variable "eks_custom_role_maps" {
  type        = list(object({ rolearn = string, username = string, groups = list(string) }))
  description = "Custom role maps for aws auth configmap"
  default     = []
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


## Moved


# variable "pod_subnets" {
#   type        = list(object({ subnet_id = string, az = string }))
#   description = "Pod subnets and az to setup with vpc-cni"
# }


##

# variable "bastion_user" {
#   type        = string
#   description = "ec2 instance user."
#   default     = null
# }

# variable "bastion_public_ip" {
#   type        = string
#   description = "Bastion host public ip."
#   default     = null
# }

# variable "ssh_pvt_key_path" {
#   type        = string
#   description = "SSH private key filepath."
# }
