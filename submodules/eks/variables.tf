variable "deploy_id" {
  type        = string
  description = "Domino Deployment ID"

  validation {
    condition     = can(regex("^[a-z-0-9]{3,32}$", var.deploy_id))
    error_message = "Argument deploy_id must: start with a letter, contain lowercase alphanumeric characters(can contain hyphens[-]) with length between 3 and 32 characters."
  }
}

variable "update_kubeconfig_extra_args" {
  type        = string
  description = "Optional extra args when generating kubeconfig"
  default     = ""
}

variable "region" {
  type        = string
  description = "AWS region for the deployment"
}

variable "k8s_version" {
  type        = string
  description = "EKS cluster k8s version."
}

variable "node_groups" {
  description = "Additional EKS managed node groups definition."
  type = map(object({
    ami                  = optional(string, null)
    bootstrap_extra_args = optional(string, "")
    instance_types       = list(string)
    spot                 = optional(bool, false)
    min_per_az           = number
    max_per_az           = number
    desired_per_az       = number
    labels               = map(string)
    taints               = optional(list(object({ key = string, value = optional(string), effect = string })), [])
    tags                 = optional(map(string), {})
    instance_tags        = optional(map(string), {})
    gpu                  = optional(bool, false)
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
  description = "List of Private subnets IDs and AZ"
  type        = list(object({ subnet_id = string, az = string }))
  validation {
    condition     = length(var.private_subnets) >= 2
    error_message = "EKS deployment needs at least 2 subnets. https://docs.aws.amazon.com/eks/latest/userguide/network_reqs.html."
  }
}

variable "pod_subnets" {
  description = "List of POD subnets IDs and AZ"
  type        = list(object({ subnet_id = string, az = string }))
  validation {
    condition     = length(var.pod_subnets) != 1
    error_message = "EKS deployment needs at least 2 subnets. https://docs.aws.amazon.com/eks/latest/userguide/network_reqs.html."
  }
}

variable "vpc_id" {
  type        = string
  description = "VPC ID."
}

variable "ssh_key_pair_name" {
  type        = string
  description = "SSH key pair name."
}

variable "bastion_security_group_id" {
  type        = string
  description = "Bastion security group id."
  default     = ""
}

variable "eks_cluster_addons" {
  type        = list(string)
  description = "EKS cluster addons. vpc-cni is installed separately."
  default     = ["kube-proxy", "coredns"]
}

variable "create_bastion_sg" {
  description = "Create bastion access rules toggle."
  type        = bool
  default     = false
}

variable "node_iam_policies" {
  description = "Additional IAM Policy Arns for Nodes"
  type        = list(string)
}

variable "efs_security_group" {
  description = "Security Group ID for EFS"
  type        = string
}

variable "eks_master_role_names" {
  type        = list(string)
  description = "IAM role names to be added as masters in eks"
  default     = []
}

variable "ssh_pvt_key_path" {
  type        = string
  description = "Path to SSH private key"
  default     = ""
}

variable "bastion_user" {
  type        = string
  description = "Username for bastion instance"
  default     = ""
}

variable "bastion_public_ip" {
  type        = string
  description = "Public IP of bastion instance"
  default     = ""
}

variable "secrets_kms_key" {
  type        = string
  description = "if set, use specified key for the EKS cluster secrets"
  default     = null
}

variable "node_groups_kms_key" {
  type        = string
  description = "if set, use specified key for the EKS node groups"
  default     = null
}

variable "eks_custom_role_maps" {
  type        = list(object({ rolearn = string, username = string, groups = list(string) }))
  description = "Custom role maps for aws auth configmap"
  default     = []
}
