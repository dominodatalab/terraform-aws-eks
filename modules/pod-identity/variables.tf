variable "eks_info" {
  description = <<EOF
    cluster = {
      specs {
        name       = Cluster name.
        account_id = AWS account id where the cluster resides.
      }
    }
  EOF

  # Deliberately narrower than the irsa module's eks_info: pod identity needs no
  # OIDC provider, and requiring one here would reintroduce the coupling this
  # module exists to avoid. Terraform drops the extra attributes when a caller
  # passes the full `module.eks.info`.
  type = object({
    cluster = object({
      specs = object({
        name       = string
        account_id = string
      })
    })
  })
}

variable "region" {
  type        = string
  description = "AWS region the cluster resides in. Used to build the cluster ARN the trust policy is scoped to."
  nullable    = false
  validation {
    condition     = can(regex("^[a-z]{2,}(-[a-z0-9]+)*-\\w+-\\d+$", var.region))
    error_message = "Invalid region"
  }
}

variable "additional_pod_identity_configs" {
  description = "Input for additional EKS Pod Identity configurations"
  type = list(object({
    name                = string
    namespace           = string
    serviceaccount_name = string
    policy              = string #json
  }))

  default = []

  validation {
    condition     = alltrue([for i in var.additional_pod_identity_configs : can(jsondecode(i.policy))])
    error_message = "Invalid json found in policy"
  }

  validation {
    condition     = length(distinct([for i in var.additional_pod_identity_configs : "${i.namespace}/${i.serviceaccount_name}"])) == length(var.additional_pod_identity_configs)
    error_message = "Each namespace/serviceaccount_name pair may appear once: EKS permits only one pod identity association per pair, so a duplicate fails at apply time rather than at plan time."
  }
}
