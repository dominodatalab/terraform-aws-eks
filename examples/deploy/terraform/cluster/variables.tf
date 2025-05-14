## Used to overwrite the `eks` variable passed through the `infra` outputs.

variable "eks" {
  description = <<EOF
    run_k8s_setup = Toggle to run the k8s setup.
    service_ipv4_cidr = CIDR for EKS cluster kubernetes_network_config.
    creation_role_name = Name of the role to import.
    k8s_version = EKS cluster k8s version.
    kubeconfig = {
      extra_args = Optional extra args when generating kubeconfig.
      path       = Fully qualified path name to write the kubeconfig file.
    }
    public_access = {
      enabled = Enable EKS API public endpoint.
      cidrs   = List of CIDR ranges permitted for accessing the EKS public endpoint.
    }
    Custom role maps for aws auth configmap
    custom_role_maps = {
      rolearn  = string
      username = string
      groups   = list(string)
    }
    master_role_names  = IAM role names to be added as masters in eks.
    cluster_addons     = EKS cluster addons.
    vpc_cni            = Configuration for AWS VPC CNI
    ssm_log_group_name = CloudWatch log group to send the SSM session logs to.
    identity_providers = Configuration for IDP(Identity Provider).
    oidc_provider = Configuration for OIDC provider.
  }
  EOF

  type = object({
    run_k8s_setup      = optional(bool)
    service_ipv4_cidr  = optional(string)
    creation_role_name = optional(string, null)
    k8s_version        = optional(string)
    kubeconfig = optional(object({
      extra_args = optional(string)
      path       = optional(string)
    }), {})
    public_access = optional(object({
      enabled = optional(bool)
      cidrs   = optional(list(string))
    }), {})
    custom_role_maps = optional(list(object({
      rolearn  = string
      username = string
      groups   = list(string)
    })))
    master_role_names  = optional(list(string))
    cluster_addons     = optional(list(string))
    ssm_log_group_name = optional(string)
    vpc_cni = optional(object({
      prefix_delegation = optional(bool)
      annotate_pod_ip   = optional(bool)
    }))
    identity_providers = optional(list(object({
      client_id                     = string
      groups_claim                  = optional(string)
      groups_prefix                 = optional(string)
      identity_provider_config_name = string
      issuer_url                    = optional(string)
      required_claims               = optional(map(string))
      username_claim                = optional(string)
      username_prefix               = optional(string)
    })))
    oidc_provider = optional(object({
      create = optional(bool, true)
      oidc = optional(object({
        id  = optional(string, null)
        arn = optional(string, null)
        url = optional(string, null)
        cert = optional(object({
          thumbprint_list = optional(list(string), null)
          url             = optional(string, null)
        }), {})
      }), null)
    }), {})
  })

  default = {}
}

variable "kms_info" {
  description = <<EOF
    Overrides the KMS key information. Meant for migrated configurations.
    {
      key_id  = KMS key id.
      key_arn = KMS key arn.
      enabled = KMS key is enabled.
    }
  EOF
  type = object({
    key_id  = string
    key_arn = string
    enabled = bool
  })
  default = null
}

variable "irsa_policies" {
  description = "Mappings for custom IRSA configurations."
  type = list(object({
    name                = string
    namespace           = string
    serviceaccount_name = string
    policy              = string #json
  }))

  default = []
}

variable "irsa_external_dns" {
  description = "Mappings for custom IRSA configurations."
  type = object({
    enabled             = optional(bool, false)
    hosted_zone_name    = optional(string, null)
    namespace           = optional(string, null)
    serviceaccount_name = optional(string, null)
    rm_role_policy = optional(object({
      remove           = optional(bool, false)
      detach_from_role = optional(bool, false)
      policy_name      = optional(string, "")
    }), {})
  })

  default = {}
}

variable "use_fips_endpoint" {
  description = "Use aws FIPS endpoints"
  type        = bool
  default     = false
}

variable "external_deployments_operator" {
  description = "Config to create IRSA role for the external deployments operator."

  type = object({
    enabled                         = optional(bool, false)
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

variable "flyte" {
  description = "Config to provision the flyte infrastructure."

  type = object({
    enabled                   = optional(bool, false)
    force_destroy_on_deletion = optional(bool, true)
    platform_namespace        = optional(string, "domino-platform")
    compute_namespace         = optional(string, "domino-compute")

  })
  default = {}
}

variable "karpenter" {
  description = <<EOF
    karpenter = {
      enabled = Toggle installation of Karpenter.
      namespace = Namespace to install Karpenter.
      version = Configure the version for Karpenter.
      delete_instances_on_destroy = Toggle to delete Karpenter instances on destroy.
    }
  EOF
  type = object({
    enabled                     = optional(bool, false)
    delete_instances_on_destroy = optional(bool, true)
    namespace                   = optional(string, "karpenter")
    version                     = optional(string, "1.3.3")
    #https://karpenter.sh/docs/upgrading/compatibility/#compatibility-matrix
    #https://github.com/aws/karpenter-provider-aws/releases
  })

  default = {}
}
