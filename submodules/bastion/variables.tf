variable "deploy_id" {
  type        = string
  description = "Domino Deployment ID"
}

variable "ami_id" {
  description = "AMI ID for the bastion EC2 instance, otherwise we will use the latest 'amazon_linux_2' ami."
  type        = string
  default     = null
}

variable "instance_type" {
  description = "the bastion's instance type, if null, t2.micro is used"
  type        = string
  default     = null
}

variable "region" {
  description = "AWS region for the deployment"
  type        = string
}

variable "vpc_id" {
  description = "VPC ID."
  type        = string
}

variable "ssh_pvt_key_path" {
  description = "SSH private key filepath."
  type        = string
}

variable "public_subnet_id" {
  description = "Public subnet to create bastion host in."
  type        = string
}

variable "security_group_rules" {

  description = "Bastion host security group rules."
  type = map(object({
    protocol                 = string
    from_port                = string
    to_port                  = string
    type                     = string
    description              = string
    cidr_blocks              = list(string)
    source_security_group_id = string

  }))

  default = {
    bastion_outbound_traffic = {
      protocol                 = "-1"
      from_port                = "0"
      to_port                  = "0"
      type                     = "egress"
      description              = "Allow all outbound traffic by default"
      cidr_blocks              = ["0.0.0.0/0"]
      source_security_group_id = null
    }
    bastion_inbound_ssh = {
      protocol                 = "-1"
      from_port                = "22"
      to_port                  = "22"
      type                     = "ingress"
      description              = "Inbound ssh"
      cidr_blocks              = ["0.0.0.0/0"]
      source_security_group_id = null
    }
  }
}
