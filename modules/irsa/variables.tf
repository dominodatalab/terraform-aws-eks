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
      arn = optional(string)
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


variable "external_dns" {
  description = <<EOF
    Config to enable irsa for external-dns
    use_cluster_oidc_idp = Toogle to set the oidc idp connector in the trust policy.
    Set to `true` if the cluster and the hosted zone are in different aws accounts.
    `extra_role` attaches policy to provided role (optional)
    `rm_role_policy` used to facilitate the cleanup if a node attached policy was used previously.
  EOF

  type = object({
    enabled              = optional(bool, false)
    hosted_zone_name     = optional(string, null)
    hosted_zone_private  = optional(string, false)
    namespace            = optional(string, "domino-platform")
    serviceaccount_name  = optional(string, "external-dns")
    use_cluster_oidc_idp = optional(bool, true)
    extra_role           = optional(string, null)
    rm_role_policy = optional(object({
      remove           = optional(bool, false)
      detach_from_role = optional(bool, false)
      policy_name      = optional(string, "")
    }), {})
  })

  default = {}
  validation {
    condition     = var.external_dns.enabled ? (var.external_dns.hosted_zone_name != null && length(var.external_dns.hosted_zone_name) > 0) : true
    error_message = "Must provide a non-empty `external_dns.hosted_zone_name` if `external_dns.enabled` == true"
  }
  validation {
    condition     = !var.external_dns.enabled || (var.eks_info.cluster.oidc != null || !var.external_dns.use_cluster_oidc_idp)
    error_message = "Must provide `eks_info.cluster.oidc` if `external_dns.enabled` == true or `external_dns.use_cluster_oidc_idp` == false"
  }
}

variable "additional_irsa_configs" {
  description = "Input for additional irsa configurations"
  type = list(object({
    name                = string
    namespace           = string
    serviceaccount_name = string
    policy              = optional(string) #json
    pod_identity        = optional(bool, false)
  }))

  default = []

  validation {
    # `name` becomes an IAM role name suffix and an apps-policies path segment, so it is
    # constrained here rather than at either use.
    condition     = alltrue([for i in var.additional_irsa_configs : can(regex("^[a-zA-Z0-9-]+$", i.name))])
    error_message = "Each additional_irsa_configs name must match ^[a-zA-Z0-9-]+$"
  }

  validation {
    condition = alltrue([
      for i in var.additional_irsa_configs :
      try(jsondecode(i.policy), null) != null || fileexists("${path.module}/apps-policies/${i.name}.json.tftpl")
    ])
    error_message = "Each additional_irsa_configs entry needs either a valid json `policy` or a bundled policy file at apps-policies/<name>.json.tftpl"
  }
}

variable "filetask_objectstore" {
  description = <<EOF
    S3 Files dataset storage for Domino's s3-native filetask dataset tasks.

    `buckets` declares buckets that already exist and is used only to scope IAM -- nothing here
    creates a bucket, a file system, or a mount target. Each entry is:
      name        = bucket backing an S3 File System.
      prefix      = key prefix the file system is scoped to, omitted for a whole-bucket one.
      kms_key_arn = required only for an SSE-KMS bucket; must be a regional key ARN.
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

  validation {
    # Enabled with no buckets used to silently create no role and no association, leaving the
    # task pods on the shared node role -- the exact exposure this feature exists to remove.
    condition     = !var.filetask_objectstore.enabled || length(var.filetask_objectstore.buckets) > 0
    error_message = "filetask_objectstore.buckets must be non-empty when enabled."
  }
}

variable "use_fips_endpoint" {
  description = "Use aws FIPS endpoints"
  type        = bool
  default     = false
}


variable "netapp_trident_operator" {
  description = "Config to create IRSA role for the netapp-trident-operator."

  type = object({
    enabled             = optional(bool, false)
    namespace           = optional(string, "trident")
    serviceaccount_name = optional(string, "trident-controller")
    region              = optional(string)
  })

  default = {}
}


variable "netapp_trident_configurator" {
  description = "Config to create IRSA role for the netapp-trident-configurator."

  type = object({
    enabled             = optional(bool, false)
    namespace           = optional(string, "trident")
    serviceaccount_name = optional(string, "trident-configurator")
    region              = optional(string)
  })

  default = {}
}
