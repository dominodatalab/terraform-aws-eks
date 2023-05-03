variable "deploy_id" {
  type        = string
  description = "Domino Deployment ID"
}

variable "region" {
  description = "AWS region for the deployment"
  type        = string
  nullable    = false
  validation {
    condition     = can(regex("^([a-z]{2}-[a-z]+-[0-9])$", var.region))
    error_message = "The provided region must follow the format of AWS region names, e.g., us-west-2."
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

variable "bastion" {
  description = <<EOF
    enabled                  = Create bastion host.
    ami                      = Ami id. Defaults to latest 'amazon_linux_2' ami.
    instance_type            = Instance type.
    authorized_ssh_ip_ranges = List of CIDR ranges permitted for the bastion ssh access.
    username                 = Bastion user.
    install_binaries         = Toggle to install required Domino binaries in the bastion.
  EOF

  type = object({
    enabled                  = bool
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
