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
}

variable "k8s_version" {
  type        = string
  description = "EKS cluster k8s version."
}

variable "default_node_groups" {
  description = "EKS managed node groups definition."
  type = object(
    {
      compute = object(
        {
          ami            = optional(string)
          instance_type  = optional(string, "m5.2xlarge")
          min_per_az     = optional(number, 0)
          max_per_az     = optional(number, 10)
          desired_per_az = optional(number, 1)
          labels = optional(map(string), {
            "dominodatalab.com/node-pool" = "default"
          })
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
          ami            = optional(string)
          instance_type  = optional(string, "m5.4xlarge")
          min_per_az     = optional(number, 0)
          max_per_az     = optional(number, 10)
          desired_per_az = optional(number, 1)
          labels = optional(map(string), {
            "dominodatalab.com/node-pool" = "platform"
          })
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
          ami            = optional(string)
          instance_type  = optional(string, "g4dn.xlarge")
          min_per_az     = optional(number, 0)
          max_per_az     = optional(number, 10)
          desired_per_az = optional(number, 0)
          labels = optional(map(string), {
            "dominodatalab.com/node-pool" = "default-gpu"
            "nvidia.com/gpu"              = true
          })
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
    instance_type  = string
    min_per_az     = number
    max_per_az     = number
    desired_per_az = number
    labels         = map(string)
    volume = object({
      size = string
      type = string
    })
  }))
  default = {}
}

variable "kubeconfig_path" {
  type        = string
  description = "Kubeconfig file path."
  default     = "kubeconfig"
}

variable "private_subnets" {
  description = "Private subnets object"
  type = map(object({
    id                = string
    availability_zone = string
    cidr_block        = string
  }))
  validation {
    condition     = length(var.private_subnets) >= 2
    error_message = "EKS deployment needs at least 2 subnets. https://docs.aws.amazon.com/eks/latest/userguide/network_reqs.html."
  }
}

variable "vpc_id" {
  type        = string
  description = "VPC ID."
}

variable "ssh_pvt_key_path" {
  type        = string
  description = "SSH private key filepath."
}

variable "bastion_security_group_id" {
  type        = string
  description = "Bastion security group id."
  default     = ""
}

variable "eks_cluster_addons" {
  type        = list(string)
  description = "EKS cluster addons."
  default     = ["vpc-cni", "kube-proxy", "coredns"]
}

variable "create_bastion_sg" {
  description = "Create bastion access rules toggle."
  type        = bool
}
