variable "eks_info" {
  description = <<EOF
    cluster = {
      specs {
        name            = Cluster name.
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
        name = string
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

variable "use_cluster_odc_idp" {
  description = <<EOF
    Toogle to uset the oidc idp connector in the trust policy.
    Set to `true` if the cluster and the hosted zone are in different aws accounts.
  EOF
  type        = bool
  default     = true
}

variable "external_dns" {
  description = "Config to enable irsa for external-dns"

  type = object({
    enabled             = optional(bool, false)
    hosted_zone_name    = optional(string, null)
    hosted_zone_private = optional(string, false)
    namespace           = optional(string, "domino-platform")
    serviceaccount_name = optional(string, "external-dns")
  })

  default = {}
}

variable "additional_irsa_configs" {
  description = "Input for additional irsa configurations"
  type = list(object({
    name                = string
    namespace           = string
    serviceaccount_name = string
    policy              = string #json
  }))

  default = []

  validation {
    condition     = alltrue([for i in var.additional_irsa_configs : can(jsondecode(i.policy))])
    error_message = "Invalid json found in policy"
  }
}

variable "flyte" {
  description = <<EOF
    enabled = Whether to provision any Flyte related resources
    eks = {
      controlplane_role = Name of control plane role to create for Flyte
      dataplane_role = Name of data plane role to create for Flyte
    }
  EOF
  type = object({
    enabled = optional(bool, false)
    eks = optional(object({
      controlplane_role = optional(string, "flyte-controlplane-role")
      dataplane_role    = optional(string, "flyte-dataplane-role")
    }))
  })

  default = {}
}
