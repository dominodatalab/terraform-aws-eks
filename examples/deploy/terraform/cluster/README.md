# eks

<!-- BEGINNING OF PRE-COMMIT-TERRAFORM DOCS HOOK -->
## Requirements

| Name | Version |
|------|---------|
| <a name="requirement_terraform"></a> [terraform](#requirement\_terraform) | >= 1.4.0 |
| <a name="requirement_aws"></a> [aws](#requirement\_aws) | >= 4.0 |

## Providers

| Name | Version |
|------|---------|
| <a name="provider_terraform"></a> [terraform](#provider\_terraform) | n/a |

## Modules

| Name | Source | Version |
|------|--------|---------|
| <a name="module_eks"></a> [eks](#module\_eks) | ./../../../../modules/eks | n/a |

## Resources

| Name | Type |
|------|------|
| [terraform_remote_state.infra](https://registry.terraform.io/providers/hashicorp/terraform/latest/docs/data-sources/remote_state) | data source |

## Inputs

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|:--------:|
| <a name="input_eks"></a> [eks](#input\_eks) | creation\_role\_name = Only meant to support an imported role.<br>    k8s\_version = EKS cluster k8s version.<br>    kubeconfig = {<br>      extra\_args = Optional extra args when generating kubeconfig.<br>      path       = Fully qualified path name to write the kubeconfig file.<br>    }<br>    public\_access = {<br>      enabled = Enable EKS API public endpoint.<br>      cidrs   = List of CIDR ranges permitted for accessing the EKS public endpoint.<br>    }<br>    "Custom role maps for aws auth configmap<br>    custom\_role\_maps = {<br>      rolearn  = string<br>      username = string<br>      groups   = list(string)<br>    }<br>    master\_role\_names  = IAM role names to be added as masters in eks.<br>    cluster\_addons     = EKS cluster addons. vpc-cni is installed separately.<br>    vpc\_cni            = Configuration for AWS VPC CNI<br>    ssm\_log\_group\_name = CloudWatch log group to send the SSM session logs to.<br>    identity\_providers = Configuration for IDP(Identity Provider).<br>  } | <pre>object({<br>    creation_role_name = optional(string, null)<br>    k8s_version        = optional(string)<br>    kubeconfig = optional(object({<br>      extra_args = optional(string)<br>      path       = optional(string)<br>    }), {})<br>    public_access = optional(object({<br>      enabled = optional(bool)<br>      cidrs   = optional(list(string))<br>    }), {})<br>    custom_role_maps = optional(list(object({<br>      rolearn  = string<br>      username = string<br>      groups   = list(string)<br>    })))<br>    master_role_names  = optional(list(string))<br>    cluster_addons     = optional(list(string))<br>    ssm_log_group_name = optional(string)<br>    vpc_cni = optional(object({<br>      prefix_delegation = optional(bool)<br>    }))<br>    identity_providers = optional(list(object({<br>      client_id                     = string<br>      groups_claim                  = optional(string)<br>      groups_prefix                 = optional(string)<br>      identity_provider_config_name = string<br>      issuer_url                    = optional(string)<br>      required_claims               = optional(string)<br>      username_claim                = optional(string)<br>      username_prefix               = optional(string)<br>    })))<br>  })</pre> | `null` | no |
| <a name="input_kms_info"></a> [kms\_info](#input\_kms\_info) | Overrides the KMS key information. Meant for migrated configurations.<br>    key\_id  = KMS key id.<br>    key\_arn = KMS key arn.<br>    enabled = KMS key is enabled. | <pre>object({<br>    key_id  = string<br>    key_arn = string<br>    enabled = bool<br>  })</pre> | `null` | no |

## Outputs

| Name | Description |
|------|-------------|
| <a name="output_eks"></a> [eks](#output\_eks) | EKS details. |
| <a name="output_infra"></a> [infra](#output\_infra) | Infra details. |
<!-- END OF PRE-COMMIT-TERRAFORM DOCS HOOK -->
