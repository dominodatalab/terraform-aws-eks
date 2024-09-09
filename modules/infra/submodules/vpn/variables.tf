variable "deploy_id" {
  type        = string
  description = "Domino Deployment ID"

  validation {
    condition     = can(regex("^[a-z-0-9]{3,32}$", var.deploy_id))
    error_message = "Argument deploy_id must: start with a letter, contain lowercase alphanumeric characters(can contain hyphens[-]) with length between 3 and 32 characters."
  }
}

variable "vpn_connections" {
  description = <<EOF
    List of VPN connections, each with:
    - name: Name for identification
    - shared_ip: Customer's shared IP Address.
    - cidr_block: List of CIDR blocks for the customer's network.
  EOF
  type = list(object({
    name        = string
    shared_ip   = string
    cidr_blocks = list(string)
  }))

  validation {
    condition     = alltrue([for vpn in var.vpn_connections : can(regex("^([0-9]{1,3}\\.){3}[0-9]{1,3}$", vpn.shared_ip))])
    error_message = "Each 'shared_ip' must be a valid IP address."
  }

  validation {
    condition     = alltrue([for vpn in var.vpn_connections : alltrue([for cidr in vpn.cidr_blocks : can(cidrhost(cidr, 0))])])
    error_message = "Each 'cidr_block' must be a valid CIDR block."
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
    route_tables = object({
      public  = optional(list(string))
      private = optional(list(string))
      pod     = optional(list(string))
    })
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
    vpc_cidrs = string
  })
}
