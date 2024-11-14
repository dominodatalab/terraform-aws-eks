# flyte

<!-- BEGIN_TF_DOCS -->
## Requirements

| Name | Version |
|------|---------|
| <a name="requirement_terraform"></a> [terraform](#requirement\_terraform) | >= 1.0 |
| <a name="requirement_aws"></a> [aws](#requirement\_aws) | ~> 5.0 |
| <a name="requirement_null"></a> [null](#requirement\_null) | >= 3.1.0 |

## Providers

| Name | Version |
|------|---------|
| <a name="provider_aws"></a> [aws](#provider\_aws) | ~> 5.0 |

## Modules

No modules.

## Resources

| Name | Type |
|------|------|
| [aws_iam_policy.flyte_controlplane](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/iam_policy) | resource |
| [aws_iam_policy.flyte_dataplane](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/iam_policy) | resource |
| [aws_iam_role.flyte_controlplane](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/iam_role) | resource |
| [aws_iam_role.flyte_dataplane](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/iam_role) | resource |
| [aws_iam_role_policy_attachment.flyte_controlplane](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/iam_role_policy_attachment) | resource |
| [aws_iam_role_policy_attachment.flyte_dataplane](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/iam_role_policy_attachment) | resource |
| [aws_s3_bucket.flyte_data](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/s3_bucket) | resource |
| [aws_s3_bucket.flyte_metadata](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/s3_bucket) | resource |
| [aws_s3_bucket_cors_configuration.flyte_data](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/s3_bucket_cors_configuration) | resource |
| [aws_s3_bucket_policy.flyte_data](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/s3_bucket_policy) | resource |
| [aws_s3_bucket_policy.flyte_metadata](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/s3_bucket_policy) | resource |
| [aws_s3_bucket_server_side_encryption_configuration.flye_metadata_encryption](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/s3_bucket_server_side_encryption_configuration) | resource |
| [aws_s3_bucket_server_side_encryption_configuration.flyte_data_encryption](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/s3_bucket_server_side_encryption_configuration) | resource |
| [aws_caller_identity.aws_account](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/data-sources/caller_identity) | data source |
| [aws_iam_policy_document.flyte_controlplane](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/data-sources/iam_policy_document) | data source |
| [aws_iam_policy_document.flyte_data](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/data-sources/iam_policy_document) | data source |
| [aws_iam_policy_document.flyte_dataplane](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/data-sources/iam_policy_document) | data source |
| [aws_iam_policy_document.flyte_metadata](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/data-sources/iam_policy_document) | data source |
| [aws_partition.current](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/data-sources/partition) | data source |

## Inputs

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|:--------:|
| <a name="input_compute_namespace"></a> [compute\_namespace](#input\_compute\_namespace) | Name of Domino compute namespace for this deploy | `string` | n/a | yes |
| <a name="input_eks_info"></a> [eks\_info](#input\_eks\_info) | cluster = {<br/>      specs {<br/>        name            = Cluster name.<br/>        account\_id      = AWS account id where the cluster resides.<br/>      }<br/>      oidc = {<br/>        arn = OIDC provider ARN.<br/>        url = OIDC provider url.<br/>        cert = {<br/>          thumbprint\_list = OIDC cert thumbprints.<br/>          url             = OIDC cert URL.<br/>      }<br/>    } | <pre>object({<br/>    cluster = object({<br/>      specs = object({<br/>        name       = string<br/>        account_id = string<br/>      })<br/>      oidc = object({<br/>        arn = string<br/>        url = string<br/>        cert = object({<br/>          thumbprint_list = list(string)<br/>          url             = string<br/>        })<br/>      })<br/>    })<br/>  })</pre> | n/a | yes |
| <a name="input_force_destroy_on_deletion"></a> [force\_destroy\_on\_deletion](#input\_force\_destroy\_on\_deletion) | Whether to force destroy flyte s3 buckets on deletion | `bool` | `true` | no |
| <a name="input_kms_info"></a> [kms\_info](#input\_kms\_info) | key\_id  = KMS key id.<br/>    key\_arn = KMS key arn.<br/>    enabled = KMS key is enabled | <pre>object({<br/>    key_id  = string<br/>    key_arn = string<br/>    enabled = bool<br/>  })</pre> | n/a | yes |
| <a name="input_platform_namespace"></a> [platform\_namespace](#input\_platform\_namespace) | Name of Domino platform namespace for this deploy | `string` | n/a | yes |
| <a name="input_region"></a> [region](#input\_region) | AWS region for the deployment | `string` | n/a | yes |
| <a name="input_serviceaccount_names"></a> [serviceaccount\_names](#input\_serviceaccount\_names) | Service account names for Flyte | <pre>object({<br>    datacatalog    = optional(string, "datacatalog")<br>    flyteadmin     = optional(string, "flyteadmin")<br>    flytepropeller = optional(string, "flytepropeller")<br>    importer       = optional(string, "domino-data-importer")<br>  })</pre> | `{}` | no |

## Outputs

| Name | Description |
|------|-------------|
| <a name="output_eks"></a> [eks](#output\_eks) | Flyte eks info |
<!-- END_TF_DOCS -->
