variable "deploy_id" {
  type        = string
  description = "Domino Deployment ID"
}

variable "region" {
  description = "AWS region for the deployment"
  type        = string
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


variable "kms_key" {
  type        = string
  description = "if set, use specified key for EBS volumes"
  default     = null
}



variable "bastion" {
  description = <<EOF
    ami                      = Ami id. Defaults to latest 'amazon_linux_2' ami.
    instance_type            = Instance type.
    authorized_ssh_ip_ranges = List of CIDR ranges permitted for the bastion ssh access.
    username                 = Bastion user.
    install_binaries         = Toggle to install required Domino binaries in the bastion.
  EOF
  type = object({
    ami_id                   = optional(string, null) # default will use the latest 'amazon_linux_2' ami
    instance_type            = optional(string, "t2.micro")
    authorized_ssh_ip_ranges = optional(list(string), ["0.0.0.0/0"])
    username                 = optional(string, "ec2-user")
    install_binaries         = optional(bool, false)
  })
  default = {}
}

variable "k8s_version" {
  type        = string
  description = "K8s version used to download/install the kubectl binary"
  default     = "1.25"
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


## Moved

# variable "install_binaries" {
#   type        = bool
#   description = "Install binaries on bastion host"
#   default     = false
# }


# variable "bastion_user" {
#   type        = string
#   description = "ec2 instance user."
#   default     = "ec2-user"
#   nullable    = false
# }


# variable "ami_id" {
#   description = "AMI ID for the bastion EC2 instance, otherwise we will use the latest 'amazon_linux_2' ami."
#   type        = string
#   default     = null
# }

# variable "instance_type" {
#   description = "the bastion's instance type, if null, t2.micro is used"
#   type        = string
#   default     = null
# }

##

# variable "ssh_pvt_key_path" {
#   description = "SSH private key filepath."
#   type        = string
# }


# variable "ssh_key_pair_name" {
#   description = "AWS key_pair name."
#   type        = string
# }


###

# variable "vpc_id" {
#   description = "VPC ID."
#   type        = string
# }

# variable "public_subnet_id" {
#   description = "Public subnet to create bastion host in."
#   type        = string
# }


# variable "security_group_rules" {
#   description = "Bastion host security group rules."
#   type = map(object({
#     protocol                 = string
#     from_port                = string
#     to_port                  = string
#     type                     = string
#     description              = string
#     cidr_blocks              = list(string)
#     source_security_group_id = string
#   }))

#   default = {}
# }
