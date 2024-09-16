# external-deployments

<!-- BEGINNING OF PRE-COMMIT-TERRAFORM DOCS HOOK -->
## Requirements

| Name | Version |
|------|---------|
| <a name="requirement_terraform"></a> [terraform](#requirement\_terraform) | >= 1.0 |
| <a name="requirement_aws"></a> [aws](#requirement\_aws) | ~> 5.0 |

## Providers

| Name | Version |
|------|---------|
| <a name="provider_aws"></a> [aws](#provider\_aws) | ~> 5.0 |

## Modules

No modules.

## Resources

| Name | Type |
|------|------|
| [aws_iam_policy.operator](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/iam_policy) | resource |
| [aws_iam_role.operator](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/iam_role) | resource |
| [aws_iam_role_policy_attachment.operator](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/iam_role_policy_attachment) | resource |
| [aws_iam_policy_document.assume_any_role](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/data-sources/iam_policy_document) | data source |
| [aws_iam_policy_document.decrypt_blobs_kms](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/data-sources/iam_policy_document) | data source |
| [aws_iam_policy_document.in_account_policies](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/data-sources/iam_policy_document) | data source |
| [aws_iam_policy_document.operator_assume_role_policy](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/data-sources/iam_policy_document) | data source |
| [aws_iam_policy_document.operator_grant_policy](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/data-sources/iam_policy_document) | data source |
| [aws_iam_policy_document.self_sagemaker_assume_role](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/data-sources/iam_policy_document) | data source |
| [aws_iam_policy_document.service_account_assume_role](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/data-sources/iam_policy_document) | data source |
| [aws_partition.current](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/data-sources/partition) | data source |

## Inputs

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|:--------:|
| <a name="input_bucket_suffix"></a> [bucket\_suffix](#input\_bucket\_suffix) | Suffix for the External Deployments S3 Bucket | `string` | `"external-deployments"` | no |
| <a name="input_eks_info"></a> [eks\_info](#input\_eks\_info) | cluster = {<br>      specs {<br>        name            = Cluster name.<br>        account\_id      = AWS account id where the cluster resides.<br>      }<br>      oidc = {<br>        arn = OIDC provider ARN.<br>        url = OIDC provider url.<br>        cert = {<br>          thumbprint\_list = OIDC cert thumbprints.<br>          url             = OIDC cert URL.<br>      }<br>    } | <pre>object({<br>    cluster = object({<br>      specs = object({<br>        name       = string<br>        account_id = string<br>      })<br>      oidc = object({<br>        arn = string<br>        url = string<br>        cert = object({<br>          thumbprint_list = list(string)<br>          url             = string<br>        })<br>      })<br>    })<br>  })</pre> | n/a | yes |
| <a name="input_enable_assume_any_external_role"></a> [enable\_assume\_any\_external\_role](#input\_enable\_assume\_any\_external\_role) | Flag to indicate whether to create policies for the operator role to assume any role to deploy in any other AWS account | `bool` | `true` | no |
| <a name="input_enable_in_account_deployments"></a> [enable\_in\_account\_deployments](#input\_enable\_in\_account\_deployments) | Flag to indicate whether to create policies for the operator role to deploy in this AWS account | `bool` | `true` | no |
| <a name="input_kms_info"></a> [kms\_info](#input\_kms\_info) | key\_id  = KMS key id.<br>    key\_arn = KMS key arn.<br>    enabled = KMS key is enabled | <pre>object({<br>    key_id  = string<br>    key_arn = string<br>    enabled = bool<br>  })</pre> | n/a | yes |
| <a name="input_namespace"></a> [namespace](#input\_namespace) | Name of namespace for this deploy | `string` | n/a | yes |
| <a name="input_operator_role_suffix"></a> [operator\_role\_suffix](#input\_operator\_role\_suffix) | Suffix for the External Deployments Operator IAM role | `string` | `"external-deployments-operator"` | no |
| <a name="input_operator_service_account_name"></a> [operator\_service\_account\_name](#input\_operator\_service\_account\_name) | Service account name for the External Deployments Operator | `string` | `"external-deployments-operator"` | no |
| <a name="input_region"></a> [region](#input\_region) | AWS region for the deployment | `string` | n/a | yes |
| <a name="input_repository_suffix"></a> [repository\_suffix](#input\_repository\_suffix) | Suffix for the External Deployments ECR Repository | `string` | `"external-deployments"` | no |

## Outputs

| Name | Description |
|------|-------------|
| <a name="output_bucket"></a> [bucket](#output\_bucket) | S3 Bucket for external deployment model artifacts |
| <a name="output_can_assume_any_external_role"></a> [can\_assume\_any\_external\_role](#output\_can\_assume\_any\_external\_role) | Indicates whether policies have been created for the operator role to assume any role to deploy in any other AWS account |
| <a name="output_can_deploy_in_account"></a> [can\_deploy\_in\_account](#output\_can\_deploy\_in\_account) | Indicates whether policies for the operator role to deploy in this AWS account have been created |
| <a name="output_operator_role_arn"></a> [operator\_role\_arn](#output\_operator\_role\_arn) | Operator IAM Role ARN |
| <a name="output_operator_service_account_name"></a> [operator\_service\_account\_name](#output\_operator\_service\_account\_name) | Operator Service Account Name |
| <a name="output_repository"></a> [repository](#output\_repository) | ECR Repository for external deployment images |
<!-- END OF PRE-COMMIT-TERRAFORM DOCS HOOK -->
