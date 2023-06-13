# tests

<!-- BEGINNING OF PRE-COMMIT-TERRAFORM DOCS HOOK -->
## Requirements

| Name | Version |
|------|---------|
| <a name="requirement_terraform"></a> [terraform](#requirement\_terraform) | >= 1.4.0 |
| <a name="requirement_aws"></a> [aws](#requirement\_aws) | ~> 5.0 |
| <a name="requirement_random"></a> [random](#requirement\_random) | ~> 3.0 |

## Providers

| Name | Version |
|------|---------|
| <a name="provider_aws"></a> [aws](#provider\_aws) | ~> 5.0 |

## Modules

| Name | Source | Version |
|------|--------|---------|
| <a name="module_domino_eks"></a> [domino\_eks](#module\_domino\_eks) | github.com/dominodatalab/terraform-aws-eks.git | v2.1.6 |

## Resources

| Name | Type |
|------|------|
| [aws_ami.eks_node](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/data-sources/ami) | data source |

## Inputs

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|:--------:|
| <a name="input_deploy_id"></a> [deploy\_id](#input\_deploy\_id) | Domino Deployment ID. | `string` | n/a | yes |
| <a name="input_k8s_version"></a> [k8s\_version](#input\_k8s\_version) | EKS cluster k8s version. | `string` | `"1.25"` | no |
| <a name="input_region"></a> [region](#input\_region) | AWS region for the deployment | `string` | `"us-west-2"` | no |
| <a name="input_tags"></a> [tags](#input\_tags) | Deployment tags. | `map(string)` | <pre>{<br>  "deploy": "test"<br>}</pre> | no |

## Outputs

| Name | Description |
|------|-------------|
| <a name="output_domino_eks"></a> [domino\_eks](#output\_domino\_eks) | EKS module outputs |
<!-- END OF PRE-COMMIT-TERRAFORM DOCS HOOK -->

<!-- BEGIN_TF_DOCS -->
## Requirements

| Name | Version |
|------|---------|
| <a name="requirement_terraform"></a> [terraform](#requirement\_terraform) | >= 1.3.0 |
| <a name="requirement_aws"></a> [aws](#requirement\_aws) | >= 4.0 |
| <a name="requirement_random"></a> [random](#requirement\_random) | ~> 3.0 |

## Providers

| Name | Version |
|------|---------|
| <a name="provider_aws.local"></a> [aws.local](#provider\_aws.local) | 4.33.0 |

## Modules

| Name | Source | Version |
|------|--------|---------|
| <a name="module_domino_eks"></a> [domino\_eks](#module\_domino\_eks) | git@github.com:dominodatalab/terraform-aws-eks.git | n/a |

## Resources

| Name | Type |
|------|------|
| [aws_ami.eks_node](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/data-sources/ami) | data source |

## Inputs

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|:--------:|
| <a name="input_deploy_id"></a> [deploy\_id](#input\_deploy\_id) | Domino Deployment ID. | `string` | `"dominotfeks"` | no |
| <a name="input_k8s_version"></a> [k8s\_version](#input\_k8s\_version) | EKS cluster k8s version. | `string` | `"1.25"` | no |
| <a name="input_region"></a> [region](#input\_region) | AWS region for the deployment | `string` | `"us-west-2"` | no |
| <a name="input_tags"></a> [tags](#input\_tags) | Deployment tags. | `map(string)` | <pre>{<br>  "deploy": "test"<br>}</pre> | no |

## Outputs

| Name | Description |
|------|-------------|
| <a name="output_domino_eks"></a> [domino\_eks](#output\_domino\_eks) | EKS module outputs |
<!-- END_TF_DOCS -->
