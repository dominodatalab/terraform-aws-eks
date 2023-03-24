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
    ami_id                   = optional(string) # default will use the latest 'amazon_linux_2' ami
    instance_type            = optional(string)
    authorized_ssh_ip_ranges = optional(list(string))
    username                 = optional(string)
    install_binaries         = optional(bool)
  })
}

variable "k8s_version" {
  type        = string
  description = "K8s version used to download/install the kubectl binary"
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
