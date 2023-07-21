## Used to overwrite the `k8s_version` provided at initial creation.
## When upgrading k8s modify on k8s-version.auto.tfvars file.
variable "k8s_version" {
  description = "Update k8s version."
  type        = string
  default     = null
}

variable "infra_state_file" {
  description = "Path to statefile for infra module"
  type        = string
  default     = null
}
