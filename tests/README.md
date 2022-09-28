# tests

<!-- BEGINNING OF PRE-COMMIT-TERRAFORM DOCS HOOK -->
## Requirements

| Name | Version |
|------|---------|
| <a name="requirement_terraform"></a> [terraform](#requirement\_terraform) | >= 1.2.0 |

## Providers

No providers.

## Modules

| Name | Source | Version |
|------|--------|---------|
| <a name="module_domino_eks"></a> [domino\_eks](#module\_domino\_eks) | ../../terraform-aws-eks | n/a |

## Resources

No resources.

## Inputs

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|:--------:|
| <a name="input_deploy_id"></a> [deploy\_id](#input\_deploy\_id) | Domino Deployment ID. | `string` | `"domino-eks-test"` | no |
| <a name="input_k8s_version"></a> [k8s\_version](#input\_k8s\_version) | EKS cluster k8s version. | `string` | `"1.23"` | no |
| <a name="input_region"></a> [region](#input\_region) | AWS region for the deployment | `string` | `"us-west-2"` | no |
| <a name="input_tags"></a> [tags](#input\_tags) | Deployment tags. | `map(string)` | <pre>{<br>  "deploy_id": "domino-eks-test",<br>  "deploy_tag": "domino-eks-test",<br>  "deploy_type": "terraform-aws-eks",<br>  "domino-deploy-id": "domino-eks-test"<br>}</pre> | no |

## Outputs

| Name | Description |
|------|-------------|
| <a name="output_domino_eks"></a> [domino\_eks](#output\_domino\_eks) | EKS module outputs |
<!-- END OF PRE-COMMIT-TERRAFORM DOCS HOOK -->
