## Used to overwrite the `k8s_version` provided at initial creation.
## When upgrading k8s, create/modify k8s-version.auto.tfvars with desired `k8s_version` value.
variable "k8s_version" {
  description = "Update k8s version."
  type        = string
  default     = null
}
