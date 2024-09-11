# IRSA

This module is an opinionated implementation of predefined and custom `irsa` roles for EKS.

## Predefined IRSA roles

* `external-dns`

<!-- BEGINNING OF PRE-COMMIT-TERRAFORM DOCS HOOK -->
## Requirements

| Name | Version |
|------|---------|
| <a name="requirement_terraform"></a> [terraform](#requirement\_terraform) | >= 1.6.0 |
| <a name="requirement_aws"></a> [aws](#requirement\_aws) | ~> 5.0 |

## Providers

| Name | Version |
|------|---------|
| <a name="provider_aws"></a> [aws](#provider\_aws) | ~> 5.0 |
| <a name="provider_terraform"></a> [terraform](#provider\_terraform) | n/a |

## Modules

No modules.

## Resources

| Name | Type |
|------|------|
| [aws_iam_openid_connect_provider.this](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/iam_openid_connect_provider) | resource |
| [aws_iam_policy.external_deployments_operator](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/iam_policy) | resource |
| [aws_iam_policy.external_dns](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/iam_policy) | resource |
| [aws_iam_policy.this](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/iam_policy) | resource |
| [aws_iam_policy.trident_operator](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/iam_policy) | resource |
| [aws_iam_role.external_deployments_operator](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/iam_role) | resource |
| [aws_iam_role.external_dns](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/iam_role) | resource |
| [aws_iam_role.this](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/iam_role) | resource |
| [aws_iam_role.trident_operator](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/iam_role) | resource |
| [aws_iam_role_policy_attachment.external_deployments_operator](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/iam_role_policy_attachment) | resource |
| [aws_iam_role_policy_attachment.external_dns](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/iam_role_policy_attachment) | resource |
| [aws_iam_role_policy_attachment.this](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/iam_role_policy_attachment) | resource |
| [aws_iam_role_policy_attachment.trident_operator](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/iam_role_policy_attachment) | resource |
| [terraform_data.delete_route53_policy](https://registry.terraform.io/providers/hashicorp/terraform/latest/docs/resources/data) | resource |
| [aws_caller_identity.aws_account](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/data-sources/caller_identity) | data source |
| [aws_iam_policy_document.assume_any_role](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/data-sources/iam_policy_document) | data source |
| [aws_iam_policy_document.decrypt_blobs_kms](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/data-sources/iam_policy_document) | data source |
| [aws_iam_policy_document.external_dns](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/data-sources/iam_policy_document) | data source |
| [aws_iam_policy_document.in_account_policies](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/data-sources/iam_policy_document) | data source |
| [aws_iam_policy_document.operator_assume_role_policy](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/data-sources/iam_policy_document) | data source |
| [aws_iam_policy_document.operator_grant_policy](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/data-sources/iam_policy_document) | data source |
| [aws_iam_policy_document.self_sagemaker_assume_role](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/data-sources/iam_policy_document) | data source |
| [aws_iam_policy_document.service_account_assume_role](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/data-sources/iam_policy_document) | data source |
| [aws_iam_policy_document.trident_operator](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/data-sources/iam_policy_document) | data source |
| [aws_partition.current](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/data-sources/partition) | data source |
| [aws_route53_zone.hosted](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/data-sources/route53_zone) | data source |

## Inputs

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|:--------:|
| <a name="input_additional_irsa_configs"></a> [additional\_irsa\_configs](#input\_additional\_irsa\_configs) | Input for additional irsa configurations | <pre>list(object({<br>    name                = string<br>    namespace           = string<br>    serviceaccount_name = string<br>    policy              = string #json<br>  }))</pre> | `[]` | no |
| <a name="input_eks_info"></a> [eks\_info](#input\_eks\_info) | cluster = {<br>      specs {<br>        name            = Cluster name.<br>        account\_id      = AWS account id where the cluster resides.<br>      }<br>      oidc = {<br>        arn = OIDC provider ARN.<br>        url = OIDC provider url.<br>        cert = {<br>          thumbprint\_list = OIDC cert thumbprints.<br>          url             = OIDC cert URL.<br>      }<br>    } | <pre>object({<br>    nodes = object({<br>      roles = list(object({<br>        arn  = string<br>        name = string<br>      }))<br>    })<br>    cluster = object({<br>      specs = object({<br>        name       = string<br>        account_id = string<br>      })<br>      oidc = object({<br>        arn = string<br>        url = string<br>        cert = object({<br>          thumbprint_list = list(string)<br>          url             = string<br>        })<br>      })<br>    })<br>  })</pre> | n/a | yes |
| <a name="input_external_deployments_operator"></a> [external\_deployments\_operator](#input\_external\_deployments\_operator) | Config to create IRSA role for the external deployments operator. | <pre>object({<br>    enabled                   = optional(bool, false)<br>    namespace                 = optional(string, "domino-compute")<br>    service_account_name      = optional(string, "pham-juno-operator")<br>    role_suffix               = optional(string, "external-deployments-operator")<br>    repository_suffix         = optional(string, "external-deployments")<br>    bucket_suffix             = optional(string, "external-deployments")<br>    grant_assume_any_role     = optional(bool, true)<br>    grant_in_account_policies = optional(bool, true)<br>  })</pre> | `{}` | no |
| <a name="input_external_dns"></a> [external\_dns](#input\_external\_dns) | Config to enable irsa for external-dns | <pre>object({<br>    enabled             = optional(bool, false)<br>    hosted_zone_name    = optional(string, null)<br>    hosted_zone_private = optional(string, false)<br>    namespace           = optional(string, "domino-platform")<br>    serviceaccount_name = optional(string, "external-dns")<br>    rm_role_policy = optional(object({<br>      remove           = optional(bool, false)<br>      detach_from_role = optional(bool, false)<br>      policy_name      = optional(string, "")<br>    }), {})<br>  })</pre> | `{}` | no |
| <a name="input_kms_info"></a> [kms\_info](#input\_kms\_info) | key\_id  = KMS key id.<br>    key\_arn = KMS key arn.<br>    enabled = KMS key is enabled | <pre>object({<br>    key_id  = string<br>    key_arn = string<br>    enabled = bool<br>  })</pre> | n/a | yes |
| <a name="input_netapp_trident_operator"></a> [netapp\_trident\_operator](#input\_netapp\_trident\_operator) | Config to create IRSA role for the netapp-trident-operator. | <pre>object({<br>    enabled             = optional(bool, false)<br>    namespace           = optional(string, "trident")<br>    serviceaccount_name = optional(string, "trident-controller")<br>    region              = optional(string)<br>  })</pre> | `{}` | no |
| <a name="input_region"></a> [region](#input\_region) | AWS region for the deployment | `string` | n/a | yes |
| <a name="input_use_cluster_odc_idp"></a> [use\_cluster\_odc\_idp](#input\_use\_cluster\_odc\_idp) | Toogle to uset the oidc idp connector in the trust policy.<br>    Set to `true` if the cluster and the hosted zone are in different aws accounts.<br>    `rm_role_policy` used to facilitiate the cleanup if a node attached policy was used previously. | `bool` | `true` | no |
| <a name="input_use_fips_endpoint"></a> [use\_fips\_endpoint](#input\_use\_fips\_endpoint) | Use aws FIPS endpoints | `bool` | `false` | no |

## Outputs

| Name | Description |
|------|-------------|
| <a name="output_external_deployments_operator"></a> [external\_deployments\_operator](#output\_external\_deployments\_operator) | External deployments operator role info |
| <a name="output_external_dns"></a> [external\_dns](#output\_external\_dns) | External\_dns info |
| <a name="output_netapp_trident_operator"></a> [netapp\_trident\_operator](#output\_netapp\_trident\_operator) | NetApp Astra Trident NETAPP Operator role info |
| <a name="output_roles"></a> [roles](#output\_roles) | Roles mapping info |
<!-- END OF PRE-COMMIT-TERRAFORM DOCS HOOK -->
