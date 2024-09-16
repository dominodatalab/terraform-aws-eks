variable "operator_service_account_name" {
  description = "Service account name for the External Deployments Operator"
  type        = string
  default     = "external-deployments-operator"
}

variable "operator_role_suffix" {
  description = "Suffix for the External Deployments Operator IAM role"
  type        = string
  default     = "external-deployments-operator"
}

variable "repository_suffix" {
  description = "Suffix for the External Deployments ECR Repository"
  type        = string
  default     = "external-deployments"
}

variable "bucket_suffix" {
  description = "Suffix for the External Deployments S3 Bucket"
  type        = string
  default     = "external-deployments"
}

variable "enable_assume_any_external_role" {
  description = "Flag to indicate whether to create policies for the operator role to assume any role to deploy in any other AWS account"
  type        = bool
  default     = true
}

variable "enable_in_account_deployments" {
  description = "Flag to indicate whether to create policies for the operator role to deploy in this AWS account"
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

variable "namespace" {
  description = "Name of namespace for this deploy"
  type        = string
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
