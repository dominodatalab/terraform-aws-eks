# eks

<!-- BEGIN_TF_DOCS -->
## Requirements

| Name | Version |
|------|---------|
| <a name="requirement_terraform"></a> [terraform](#requirement\_terraform) | >= 1.4.0 |
| <a name="requirement_aws"></a> [aws](#requirement\_aws) | >= 4.0 |

## Providers

| Name | Version |
|------|---------|
| <a name="provider_aws"></a> [aws](#provider\_aws) | >= 4.0 |
| <a name="provider_aws.global"></a> [aws.global](#provider\_aws.global) | >= 4.0 |
| <a name="provider_terraform"></a> [terraform](#provider\_terraform) | n/a |

## Modules

| Name | Source | Version |
|------|--------|---------|
| <a name="module_eks"></a> [eks](#module\_eks) | ./../../../../modules/eks | n/a |
| <a name="module_external_deployments_operator"></a> [external\_deployments\_operator](#module\_external\_deployments\_operator) | ./../../../../modules/external-deployments | n/a |
| <a name="module_flyte"></a> [flyte](#module\_flyte) | ./../../../../modules/flyte | n/a |
| <a name="module_irsa_external_dns"></a> [irsa\_external\_dns](#module\_irsa\_external\_dns) | ./../../../../modules/irsa | n/a |
| <a name="module_irsa_policies"></a> [irsa\_policies](#module\_irsa\_policies) | ./../../../../modules/irsa | n/a |

## Resources

| Name | Type |
|------|------|
| [aws_caller_identity.global](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/data-sources/caller_identity) | data source |
| [aws_caller_identity.this](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/data-sources/caller_identity) | data source |
| [terraform_remote_state.infra](https://registry.terraform.io/providers/hashicorp/terraform/latest/docs/data-sources/remote_state) | data source |

## Inputs

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|:--------:|
| <a name="input_eks"></a> [eks](#input\_eks) | run\_k8s\_setup = Toggle to run the k8s setup.<br/>    service\_ipv4\_cidr = CIDR for EKS cluster kubernetes\_network\_config.<br/>    creation\_role\_name = Name of the role to import.<br/>    k8s\_version = EKS cluster k8s version.<br/>    kubeconfig = {<br/>      extra\_args = Optional extra args when generating kubeconfig.<br/>      path       = Fully qualified path name to write the kubeconfig file.<br/>    }<br/>    public\_access = {<br/>      enabled = Enable EKS API public endpoint.<br/>      cidrs   = List of CIDR ranges permitted for accessing the EKS public endpoint.<br/>    }<br/>    Custom role maps for aws auth configmap<br/>    custom\_role\_maps = {<br/>      rolearn  = string<br/>      username = string<br/>      groups   = list(string)<br/>    }<br/>    master\_role\_names  = IAM role names to be added as masters in eks.<br/>    cluster\_addons     = EKS cluster addons.<br/>    vpc\_cni            = Configuration for AWS VPC CNI<br/>    ssm\_log\_group\_name = CloudWatch log group to send the SSM session logs to.<br/>    identity\_providers = Configuration for IDP(Identity Provider).<br/>  } | <pre>object({<br/>    run_k8s_setup      = optional(bool)<br/>    service_ipv4_cidr  = optional(string)<br/>    creation_role_name = optional(string, null)<br/>    k8s_version        = optional(string)<br/>    kubeconfig = optional(object({<br/>      extra_args = optional(string)<br/>      path       = optional(string)<br/>    }), {})<br/>    public_access = optional(object({<br/>      enabled = optional(bool)<br/>      cidrs   = optional(list(string))<br/>    }), {})<br/>    custom_role_maps = optional(list(object({<br/>      rolearn  = string<br/>      username = string<br/>      groups   = list(string)<br/>    })))<br/>    master_role_names  = optional(list(string))<br/>    cluster_addons     = optional(list(string))<br/>    ssm_log_group_name = optional(string)<br/>    vpc_cni = optional(object({<br/>      prefix_delegation = optional(bool)<br/>      annotate_pod_ip   = optional(bool)<br/>    }))<br/>    identity_providers = optional(list(object({<br/>      client_id                     = string<br/>      groups_claim                  = optional(string)<br/>      groups_prefix                 = optional(string)<br/>      identity_provider_config_name = string<br/>      issuer_url                    = optional(string)<br/>      required_claims               = optional(map(string))<br/>      username_claim                = optional(string)<br/>      username_prefix               = optional(string)<br/>    })))<br/>  })</pre> | `{}` | no |
| <a name="input_external_deployments_operator"></a> [external\_deployments\_operator](#input\_external\_deployments\_operator) | Config to create IRSA role for the external deployments operator. | <pre>object({<br/>    enabled                         = optional(bool, false)<br/>    namespace                       = optional(string, "domino-compute")<br/>    operator_service_account_name   = optional(string, "pham-juno-operator")<br/>    operator_role_suffix            = optional(string, "external-deployments-operator")<br/>    repository_suffix               = optional(string, "external-deployments")<br/>    bucket_suffix                   = optional(string, "external-deployments")<br/>    enable_assume_any_external_role = optional(bool, true)<br/>    enable_in_account_deployments   = optional(bool, true)<br/>  })</pre> | `{}` | no |
| <a name="input_flyte"></a> [flyte](#input\_flyte) | Config to provision the flyte infrastructure. | <pre>object({<br/>    enabled                   = optional(bool, false)<br/>    force_destroy_on_deletion = optional(bool, true)<br/>    platform_namespace        = optional(string, "domino-platform")<br/>    compute_namespace         = optional(string, "domino-compute")<br/><br/>  })</pre> | `{}` | no |
| <a name="input_irsa_external_dns"></a> [irsa\_external\_dns](#input\_irsa\_external\_dns) | Mappings for custom IRSA configurations. | <pre>object({<br/>    enabled             = optional(bool, false)<br/>    hosted_zone_name    = optional(string, null)<br/>    namespace           = optional(string, null)<br/>    serviceaccount_name = optional(string, null)<br/>    rm_role_policy = optional(object({<br/>      remove           = optional(bool, false)<br/>      detach_from_role = optional(bool, false)<br/>      policy_name      = optional(string, "")<br/>    }), {})<br/>  })</pre> | `{}` | no |
| <a name="input_irsa_policies"></a> [irsa\_policies](#input\_irsa\_policies) | Mappings for custom IRSA configurations. | <pre>list(object({<br/>    name                = string<br/>    namespace           = string<br/>    serviceaccount_name = string<br/>    policy              = string #json<br/>  }))</pre> | `[]` | no |
| <a name="input_karpenter"></a> [karpenter](#input\_karpenter) | karpenter = {<br/>      enabled = Toggle installation of Karpenter.<br/>      namespace = Namespace to install Karpenter.<br/>      version = Configure the version for Karpenter.<br/>    } | <pre>object({<br/>    enabled   = optional(bool, false)<br/>    namespace = optional(string, "karpenter")<br/>    version   = optional(string, "1.3.3")<br/>    #https://karpenter.sh/docs/upgrading/compatibility/#compatibility-matrix<br/>    #https://github.com/aws/karpenter-provider-aws/releases<br/>  })</pre> | `{}` | no |
| <a name="input_kms_info"></a> [kms\_info](#input\_kms\_info) | Overrides the KMS key information. Meant for migrated configurations.<br/>    {<br/>      key\_id  = KMS key id.<br/>      key\_arn = KMS key arn.<br/>      enabled = KMS key is enabled.<br/>    } | <pre>object({<br/>    key_id  = string<br/>    key_arn = string<br/>    enabled = bool<br/>  })</pre> | `null` | no |
| <a name="input_use_fips_endpoint"></a> [use\_fips\_endpoint](#input\_use\_fips\_endpoint) | Use aws FIPS endpoints | `bool` | `false` | no |

## Outputs

| Name | Description |
|------|-------------|
| <a name="output_eks"></a> [eks](#output\_eks) | EKS details. |
| <a name="output_external_deployments_operator"></a> [external\_deployments\_operator](#output\_external\_deployments\_operator) | External deployments operator details. |
| <a name="output_external_dns_irsa_role_arn"></a> [external\_dns\_irsa\_role\_arn](#output\_external\_dns\_irsa\_role\_arn) | "External\_dns info"<br/>  {<br/>    irsa\_role = irsa role arn.<br/>    zone\_id   = hosted zone id for external\_dns Iam policy<br/>    zone\_name = hosted zone name for external\_dns Iam policy<br/>  } |
| <a name="output_flyte"></a> [flyte](#output\_flyte) | Flyte details. |
| <a name="output_infra"></a> [infra](#output\_infra) | Infra details. |
<!-- END_TF_DOCS -->
