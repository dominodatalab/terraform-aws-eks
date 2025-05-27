variable "force_destroy_on_deletion" {
  description = "Whether to force destroy flyte s3 buckets on deletion"
  type        = bool
  default     = true
}

variable "eks_info" {
  description = <<EOF
    cluster = {
      specs {
        name            = Cluster name.
        account_id      = AWS account id where the cluster resides.
      }
      oidc = {
        arn = OIDC provider ARN.
        url = OIDC provider url.
        cert = {
          thumbprint_list = OIDC cert thumbprints.
          url             = OIDC cert URL.
      }
    }
  EOF
  type = object({
    cluster = object({
      specs = object({
        name       = string
        account_id = string
      })
      oidc = object({
        arn             = string
        id              = string
        url             = string
        thumbprint_list = list(string)
      })
    })
  })
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
