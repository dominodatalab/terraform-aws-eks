variable "deploy_id" {
  type        = string
  description = "Domino Deployment ID."
  default     = "domino-eks"
  nullable    = false

  validation {
    condition     = length(var.deploy_id) >= 3 && length(var.deploy_id) <= 32 && can(regex("^[a-z]([-a-z0-9]*[a-z0-9])$", var.deploy_id))
    error_message = <<EOT
      Variable deploy_id must:
      1. Length must be between 3 and 32 characters.
      2. Start with a letter.
      3. End with a letter or digit.
      4. Contain lowercase Alphanumeric characters and hyphens.
    EOT
  }
}

variable "region" {
  type        = string
  description = "AWS region for the deployment"
}

variable "number_of_azs" {
  type        = number
  description = "Number of AZ to distribute the deployment, EKS needs at least 2."
  default     = 3
  validation {
    condition     = var.number_of_azs >= 2
    error_message = "EKS deployment needs at least 2 zones."
  }
}

variable "availability_zones" {
  type        = list(string)
  description = <<EOT
    List of Availibility zones to distribute the deployment, EKS needs at least 2,https://docs.aws.amazon.com/eks/latest/userguide/network_reqs.html.
    Note that setting this variable bypasses validation of the status of the zones data 'aws_availability_zones' 'available'.
    Caller is responsible for validating status of these zones.
  EOT

  validation {
    condition     = length(var.availability_zones) == 0 || length(var.availability_zones) >= 2
    error_message = "EKS deployment needs at least 2 zones."
  }
  default = []
}

variable "route53_hosted_zone_name" {
  type        = string
  description = "Optional hosted zone for External DNSone."
  default     = ""
}

variable "tags" {
  type        = map(string)
  description = "Deployment tags."
  default     = {}
}

variable "k8s_version" {
  type        = string
  description = "EKS cluster k8s version."
  default     = "1.23"
}

variable "public_cidr_network_bits" {
  type        = number
  description = "Number of network bits to allocate to the public subnet. i.e /27 -> 32 IPs."
  default     = 27
}

variable "private_cidr_network_bits" {
  type        = number
  description = "Number of network bits to allocate to the private subnet. i.e /19 -> 8,192 IPs."
  default     = 19
}

variable "default_node_groups" {
  description = "EKS managed node groups definition."
  type = object(
    {
      compute = object(
        {
          name           = optional(string, "compute")
          ami            = optional(string)
          instance_type  = optional(string, "m5.2xlarge")
          min_per_az     = optional(number, 0)
          max_per_az     = optional(number, 10)
          desired_per_az = optional(number, 1)
          volume = optional(object(
            {
              size = optional(number, 100)
              type = optional(string, "gp3")
            }),
            {
              size = 100
              type = "gp3"
            }
          )
      }),
      platform = object(
        {
          name           = optional(string, "platform")
          ami            = optional(string)
          instance_type  = optional(string, "m5.4xlarge")
          min_per_az     = optional(number, 0)
          max_per_az     = optional(number, 10)
          desired_per_az = optional(number, 1)
          volume = optional(object(
            {
              size = optional(number, 100)
              type = optional(string, "gp3")
            }),
            {
              size = 100
              type = "gp3"
            }
          )
      }),
      gpu = object(
        {
          name           = optional(string, "gpu")
          ami            = optional(string)
          instance_type  = optional(string, "g4dn.xlarge")
          min_per_az     = optional(number, 0)
          max_per_az     = optional(number, 10)
          desired_per_az = optional(number, 0)
          volume = optional(object(
            {
              size = optional(number, 100)
              type = optional(string, "gp3")
            }),
            {
              size = 100
              type = "gp3"
            }
          )
      })
  })
  default = {
    compute  = {}
    platform = {}
    gpu      = {}
  }
}

variable "additional_node_groups" {
  description = "Additional EKS managed node groups definition."
  type = map(object({
    ami            = optional(string)
    name           = string
    instance_type  = string
    min_per_az     = number
    max_per_az     = number
    desired_per_az = number
    label          = string
    volume = object({
      size = string
      type = string
    })
  }))
  default = {}
}

variable "base_cidr_block" {
  type        = string
  default     = "10.0.0.0/16"
  description = "CIDR block to serve the main private and public subnets."
  validation {
    condition = (
      try(cidrhost(var.base_cidr_block, 0), null) == regex("^(.*)/", var.base_cidr_block)[0] &&
      try(cidrnetmask(var.base_cidr_block), null) == "255.255.0.0"
    )
    error_message = "Argument base_cidr_block must be a valid CIDR block."
  }
}

variable "eks_master_role_names" {
  type        = list(string)
  description = "IAM role names to be added as masters in eks."
  default     = []
}

variable "vpc_id" {
  type        = string
  description = "VPC ID for bringing your own vpc, will bypass creation of such."
  default     = ""
}

variable "create_bastion" {
  type        = bool
  description = "Create bastion toggle."
  default     = false
}

variable "bastion_ami_id" {
  description = "AMI ID for the bastion EC2 instance, otherwise we will use the latest 'amazon_linux_2' ami"
  type        = string
  default     = ""
}

variable "efs_access_point_path" {
  type        = string
  description = "Filesystem path for efs."
  default     = "/domino"

}

variable "ssh_pvt_key_path" {
  type        = string
  description = "SSH private key filepath."
  validation {
    condition     = fileexists(var.ssh_pvt_key_path)
    error_message = "Private key does not exist. Please provide the right path or generate a key with the following command: ssh-keygen -q -P '' -t rsa -b 4096 -m PEM -f domino.pem"
  }
}

variable "s3_force_destroy_on_deletion" {
  description = "Toogle to allow recursive deletion of all objects in the s3 buckets. if 'false' terraform will NOT be able to delete non-empty buckets"
  type        = bool
  default     = false
}

variable "kubeconfig_path" {
  description = "fully qualified path name to write the kubeconfig file"
  type        = string
  default     = ""
}
