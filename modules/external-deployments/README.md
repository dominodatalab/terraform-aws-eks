# external-deployments

<!-- BEGIN_TF_DOCS -->
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
| <a name="input_eks_info"></a> [eks\_info](#input\_eks\_info) | cluster = {<br/>      specs {<br/>        name            = Cluster name.<br/>        account\_id      = AWS account id where the cluster resides.<br/>      }<br/>      oidc = {<br/>        arn = OIDC provider ARN.<br/>        url = OIDC provider url.<br/>        cert = {<br/>          thumbprint\_list = OIDC cert thumbprints.<br/>          url             = OIDC cert URL.<br/>      }<br/>    } | <pre>object({<br/>    cluster = object({<br/>      specs = object({<br/>        name       = string<br/>        account_id = string<br/>      })<br/>      oidc = object({<br/>        arn = string<br/>        url = string<br/>        cert = object({<br/>          thumbprint_list = list(string)<br/>          url             = string<br/>        })<br/>      })<br/>    })<br/>  })</pre> | n/a | yes |
| <a name="input_external_deployments"></a> [external\_deployments](#input\_external\_deployments) | Config to create IRSA role for the external deployments operator. | <pre>object({<br/>    namespace                       = optional(string, "domino-compute")<br/>    operator_service_account_name   = optional(string, "pham-juno-operator")<br/>    operator_role_suffix            = optional(string, "external-deployments-operator")<br/>    repository_suffix               = optional(string, "external-deployments")<br/>    bucket_suffix                   = optional(string, "external-deployments")<br/>    enable_assume_any_external_role = optional(bool, true)<br/>    enable_in_account_deployments   = optional(bool, true)<br/>  })</pre> | `{}` | no |
| <a name="input_kms_info"></a> [kms\_info](#input\_kms\_info) | key\_id  = KMS key id.<br/>    key\_arn = KMS key arn.<br/>    enabled = KMS key is enabled | <pre>object({<br/>    key_id  = string<br/>    key_arn = string<br/>    enabled = bool<br/>  })</pre> | n/a | yes |
| <a name="input_region"></a> [region](#input\_region) | AWS region for the deployment | `string` | n/a | yes |

## Outputs

| Name | Description |
|------|-------------|
| <a name="output_eks"></a> [eks](#output\_eks) | External deployments eks info |
<!-- END_TF_DOCS -->
