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
        arn = string
        url = string
        cert = object({
          thumbprint_list = list(string)
          url             = string
        })
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