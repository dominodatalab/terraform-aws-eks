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

}

variable "bastion_public_ip" {
  type        = string
  description = "Bastion host public ip."
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
  default     = "v1.11.0"
}
