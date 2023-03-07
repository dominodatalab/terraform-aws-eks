variable "kubeconfig_path" {
  type        = string
  description = "Kubeconfig filename."
  default     = "kubeconfig"
}

variable "ssh_pvt_key_path" {
  type        = string
  description = "SSH private key filepath."
}

variable "bastion_user" {
  type        = string
  description = "ec2 instance user."
  default     = "ec2-user"
  nullable    = false
}

variable "bastion_public_ip" {
  type        = string
  description = "Bastion host public ip."
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

variable "pod_subnets" {
  type        = list(object({ subnet_id = string, az = string }))
  description = "Pod subnets and az to setup with vpc-cni"
}

variable "eks_custom_role_maps" {
  type        = list(object({ rolearn = string, username = string, groups = list(string) }))
  description = "Custom role maps for aws auth configmap"
  default     = []
}
