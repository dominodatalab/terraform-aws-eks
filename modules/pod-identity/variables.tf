variable "eks_info" {
  description = <<EOF
    cluster = {
      specs {
        name       = Cluster name.
        account_id = AWS account id where the cluster resides.
      }
    }
  EOF

  # Narrower than the irsa module's eks_info -- no OIDC provider; see README.md. A caller may
  # still pass the full `module.eks.info`, since Terraform drops the extra attributes.
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

variable "filetask_objectstore" {
  description = <<EOF
    S3 Files dataset storage for Domino's s3-native dataset tasks.

    `buckets` declares buckets that already exist and is used only to scope IAM -- nothing here
    creates a bucket, a file system, or a mount target. Each entry is:
      name        = bucket backing an S3 File System.
      prefix      = key prefix the file system is scoped to, omitted for a whole-bucket one.
      kms_key_arn = required only for an SSE-KMS bucket; must be a regional key ARN.

    The ServiceAccount name is part of the supported interface: the association is keyed on it,
    and so is the Domino chart that creates the account. Changing it breaks every bound role.
  EOF

  type = object({
    enabled             = optional(bool, false)
    namespace           = optional(string, "domino-compute")
    serviceaccount_name = optional(string, "domino-filetask-objectstore")
    buckets = optional(list(object({
      name        = string
      prefix      = optional(string)
      kms_key_arn = optional(string)
    })), [])
  })

  default  = {}
  nullable = false

  validation {
    condition     = alltrue([for b in var.filetask_objectstore.buckets : can(regex("^[A-Za-z0-9._-]+$", b.name))])
    error_message = "Each filetask_objectstore bucket name must match ^[A-Za-z0-9._-]+$."
  }

  validation {
    # A wildcard here spans `/`, so `data*` would also grant <bucket>/database-backups/* -- a
    # path that reads like one folder. Use one bucket entry per prefix instead.
    condition = alltrue([
      for b in var.filetask_objectstore.buckets :
      b.prefix == null || !can(regex("[*?]|\\$\\{", b.prefix))
    ])
    error_message = "filetask_objectstore prefixes must be literal: no '*', '?' or '$${...}'. Use one bucket entry per prefix."
  }

  validation {
    # A bare key id or an alias ARN builds a policy that reads as configured and denies every
    # operation, so reject both here rather than at first use.
    condition = alltrue([
      for b in var.filetask_objectstore.buckets :
      b.kms_key_arn == null || can(regex("^arn:[^:]+:kms:[^:]+:[0-9]{12}:key/.+$", b.kms_key_arn))
    ])
    error_message = "Each filetask_objectstore kms_key_arn must be a regional KMS key ARN: arn:<partition>:kms:<region>:<account>:key/<id>."
  }

  validation {
    condition     = !var.filetask_objectstore.enabled || length(var.filetask_objectstore.serviceaccount_name) > 0
    error_message = "filetask_objectstore.serviceaccount_name must not be empty when enabled: an association keyed on an empty name silently binds nothing."
  }
}
