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

  default = {}
}

variable "kms_key" {
  type        = string
  description = "if set, use specified key for EBS volumes"
  default     = null
}
