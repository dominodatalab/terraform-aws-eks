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
variable "k8s_cluster_endpoint" {
  type        = string
  description = "EKS cluster API endpoint."
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

variable "mallory_local_normal_port" {
  type        = string
  description = "Mallory k8s tunnel normal port."
  default     = "1315"
}

variable "mallory_local_smart_port" {
  type        = string
  description = "Mallory k8s tunnel smart(filters based on the blocked list) port."
  default     = "1316"
}

variable "calico_version" {
  type        = string
  description = "Calico operator version."
  default     = "v1.11.0"
}
