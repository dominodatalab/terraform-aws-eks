# iam-bootstrap

<!-- BEGINNING OF PRE-COMMIT-TERRAFORM DOCS HOOK -->
## Requirements

| Name | Version |
|------|---------|
| <a name="requirement_terraform"></a> [terraform](#requirement\_terraform) | >= 1.4.0 |
| <a name="requirement_aws"></a> [aws](#requirement\_aws) | >= 4.0 |

## Providers

| Name | Version |
|------|---------|
| <a name="provider_aws"></a> [aws](#provider\_aws) | >= 4.0 |

## Modules

No modules.

## Resources

| Name | Type |
|------|------|
| [aws_iam_policy.deployment](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/iam_policy) | resource |
| [aws_iam_role.deployment](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/iam_role) | resource |
| [aws_caller_identity.admin](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/data-sources/caller_identity) | data source |
| [aws_partition.current](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/data-sources/partition) | data source |

## Inputs

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|:--------:|
| <a name="input_deploy_id"></a> [deploy\_id](#input\_deploy\_id) | Domino Deployment ID | `string` | n/a | yes |
| <a name="input_iam_policy_paths"></a> [iam\_policy\_paths](#input\_iam\_policy\_paths) | IAM policies to provision and use for deployment role, can be terraform templates | `list(any)` | `[]` | no |
| <a name="input_max_session_duration"></a> [max\_session\_duration](#input\_max\_session\_duration) | Maximum session duration for role in seconds | `number` | `43200` | no |
| <a name="input_region"></a> [region](#input\_region) | AWS region for the deployment | `string` | n/a | yes |
| <a name="input_template_config"></a> [template\_config](#input\_template\_config) | Variables to use for any templating in the IAM policies. AWS account ID (as 'account\_id'), deploy\_id, region and partition are automatically included. | `map(any)` | `{}` | no |

## Outputs

| Name | Description |
|------|-------------|
| <a name="output_role_arn"></a> [role\_arn](#output\_role\_arn) | ARN of bootstrap role |
<!-- END OF PRE-COMMIT-TERRAFORM DOCS HOOK -->
