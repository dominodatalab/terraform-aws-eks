variable "force_destroy_on_deletion" {
  description = "Whether to force destroy flyte s3 buckets on deletion"
  type        = bool
  default     = true
}

variable "enable_irsa" {
  default     = false
  description = "Whether to assume AWS EKS IRSA is configured; if not, attach permissions to target_iam_role_name."
  type        = bool
}

variable "target_iam_role_name" {
  default     = null
  description = "If not using IRSA, attach new policies to this AWS IAM role"
  type        = string
}

variable "eks_cluster_name" {
  type        = string
  description = "Name of the EKS cluster running Domino workloads"
}

variable "platform_namespace" {
  description = "Name of Domino platform namespace for this deploy"
  type        = string
}

variable "compute_namespace" {
  description = "Name of Domino compute namespace for this deploy"
  type        = string
}

variable "serviceaccount_names" {
  description = "Service account names for Flyte"
  type = object({
    datacatalog    = optional(string, "datacatalog")
    flyteadmin     = optional(string, "flyteadmin")
    flytepropeller = optional(string, "flytepropeller")
  })

  default = {}
}

variable "kms_info" {
  description = <<EOF
    key_id  = KMS key id.
    key_arn = KMS key arn.
    enabled = KMS key is enabled
  EOF
  type = object({
    key_id  = string
    key_arn = string
    enabled = bool
  })
}

variable "region" {
  type        = string
  description = "AWS region for the deployment"
  nullable    = false
  validation {
    condition     = can(regex("(us(-gov)?|ap|ca|cn|eu|sa|me|af|il)-(central|(north|south)?(east|west)?)-[0-9]", var.region))
    error_message = "The provided region must follow the format of AWS region names, e.g., us-west-2, us-gov-west-1."
  }
}
