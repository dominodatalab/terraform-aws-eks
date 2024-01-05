
variable "eks_info" {
  description = <<EOF
    cluster = {
      addons            = List of addons
      specs             = Cluster spes. {
        name                      = Cluster name.
        endpoint                  = Cluster endpont.
        kubernetes_network_config = Cluster k8s nw config.
      }
      version           = K8s version.
      arn               = EKS Cluster arn.
      security_group_id = EKS Cluster security group id.
      endpoint          = EKS Cluster API endpoint.
      roles             = Default IAM Roles associated with the EKS cluster. {
        name = string
        arn = string
      }
      custom_roles      = Custom IAM Roles associated with the EKS cluster. {
        rolearn  = string
        username = string
        groups   = list(string)
      }
      oidc = {
        arn = OIDC provider ARN.
        url = OIDC provider url.
        cert = {
          thumbprint_list = OIDC cert thumbprints.
          url             = OIDC cert URL.
      }
    }
    nodes = {
      security_group_id = EKS Nodes security group id.
      roles = IAM Roles associated with the EKS Nodes.{
        name = string
        arn  = string
      }
    }
    kubeconfig = Kubeconfig details.{
      path       = string
      extra_args = string
    }
  EOF
  type = object({
    k8s_pre_setup_sh_file = string
    cluster = object({
      addons = list(string)
      specs = object({
        name                      = string
        endpoint                  = string
        kubernetes_network_config = list(map(any))
        certificate_authority     = list(map(any))
      })
      version           = string
      arn               = string
      security_group_id = string
      endpoint          = string
      roles = list(object({
        name = string
        arn  = string
      }))
      custom_roles = list(object({
        rolearn  = string
        username = string
        groups   = list(string)
      }))
      oidc = object({
        arn = string
        url = string
        cert = object({
          thumbprint_list = list(string)
          url             = string

        })
      })
    })
    nodes = object({
      security_group_id = string
      roles = list(object({
        name = string
        arn  = string
      }))
    })
    kubeconfig = object({
      path       = string
      extra_args = string
    })
  })
}

variable "external_dns" {
  description = "Config to enable irsa for external-dns"

  type = object({
    enabled             = optional(bool, false)
    hosted_zone_name    = optional(string, null)
    namespace           = optional(string, "domino-platform")
    serviceaccount_name = optional(string, "external-dns")
  })

  default = {}

  validation {
    condition     = var.external_dns.enabled && var.external_dns.hosted_zone_name != null && trimspace(var.external_dns.hosted_zone_name) != ""
    error_message = "If external_dns is enabled then external_dns.hosted_zone_name must not be null nor an empty string."
  }
  validation {
    condition     = var.external_dns.enabled && var.external_dns.namespace != null && trimspace(var.external_dns.namespace) != ""
    error_message = "If external_dns is enabled then external_dns.namespace must not be null nor an empty string."
  }
  validation {
    condition     = var.external_dns.enabled && var.external_dns.serviceaccount_name != null && trimspace(var.external_dns.serviceaccount_name) != ""
    error_message = "If external_dns is enabled then external_dns.serviceaccount_name must not be null nor an empty string."
  }
}


variable "additional_irsa_configs" {
  description = "Input for additional irsa configurations"
  type = list(object({
    name = string
    role = object({
      name               = string
      assume_role_policy = string #jsonencode()
    })
    namespace           = string
    serviceaccount_name = string
    policy              = string #jsonencode()
  }))

  default = []
}
