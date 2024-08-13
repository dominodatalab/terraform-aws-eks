# model-deployment

<!-- BEGINNING OF PRE-COMMIT-TERRAFORM DOCS HOOK -->
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
| [aws_iam_role.model_deployment_operator](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/iam_role) | resource |

## Inputs

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|:--------:|
| <a name="input_compute_namespace"></a> [compute\_namespace](#input\_compute\_namespace) | Name of Domino compute namespace for this deploy | `string` | n/a | yes |
| <a name="input_eks_info"></a> [eks\_info](#input\_eks\_info) | cluster = {<br>      specs {<br>        name            = Cluster name.<br>        account\_id      = AWS account id where the cluster resides.<br>      }<br>      oidc = {<br>        arn = OIDC provider ARN.<br>        url = OIDC provider url.<br>        cert = {<br>          thumbprint\_list = OIDC cert thumbprints.<br>          url             = OIDC cert URL.<br>      }<br>    } | <pre>object({<br>    cluster = object({<br>      specs = object({<br>        name       = string<br>        account_id = string<br>      })<br>      oidc = object({<br>        arn = string<br>        url = string<br>        cert = object({<br>          thumbprint_list = list(string)<br>          url             = string<br>        })<br>      })<br>    })<br>  })</pre> | n/a | yes |
| <a name="input_ignore_tags"></a> [ignore\_tags](#input\_ignore\_tags) | Tag keys to be ignored by the aws provider. | `list(string)` | `[]` | no |
| <a name="input_region"></a> [region](#input\_region) | AWS region for the deployment | `string` | n/a | yes |
| <a name="input_serviceaccount_names"></a> [serviceaccount\_names](#input\_serviceaccount\_names) | Service account names for Model Deployments | <pre>object({<br>    operator = optional(string, "model-deployment-operator")<br>  })</pre> | `{}` | no |
| <a name="input_tags"></a> [tags](#input\_tags) | Deployment tags. | `map(string)` | `{}` | no |
| <a name="input_use_fips_endpoint"></a> [use\_fips\_endpoint](#input\_use\_fips\_endpoint) | Use aws FIPS endpoints | `bool` | `false` | no |

## Outputs

| Name | Description |
|------|-------------|
| <a name="output_eks"></a> [eks](#output\_eks) | Model deployment eks info |
<!-- END OF PRE-COMMIT-TERRAFORM DOCS HOOK -->
