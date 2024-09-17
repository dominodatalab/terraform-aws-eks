variable "external_deployments" {
  description = "Config to create IRSA role for the external deployments operator."

  type = object({
    namespace                       = optional(string, "domino-compute")
    operator_service_account_name   = optional(string, "pham-juno-operator")
    operator_role_suffix            = optional(string, "external-deployments-operator")
    repository_suffix               = optional(string, "external-deployments")
    bucket_suffix                   = optional(string, "external-deployments")
    enable_assume_any_external_role = optional(bool, true)
    enable_in_account_deployments   = optional(bool, true)
  })

  default = {}
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
