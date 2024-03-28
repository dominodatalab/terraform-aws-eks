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
    nodes = object({
      roles = list(object({
        arn  = string
        name = string
      }))
    })
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

variable "use_cluster_odc_idp" {
  description = <<EOF
    Toogle to uset the oidc idp connector in the trust policy.
    Set to `true` if the cluster and the hosted zone are in different aws accounts.
    `rm_role_policy` used to facilitiate the cleanup if a node attached policy was used previously.
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
    rm_role_policy = optional(object({
      remove           = optional(bool, false)
      detach_from_role = optional(bool, false)
      policy_name      = optional(string, "")
    }), {})
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

variable "use_fips_endpoints" {
  description = "Use aws FIPS endpoints"
  type        = bool
  default     = false
}
