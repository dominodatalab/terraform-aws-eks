# infra

<!-- BEGINNING OF PRE-COMMIT-TERRAFORM DOCS HOOK -->
## Requirements

No requirements.

## Providers

| Name | Version |
|------|---------|
| <a name="provider_aws"></a> [aws](#provider\_aws) | n/a |

## Modules

| Name | Source | Version |
|------|--------|---------|
| <a name="module_infra"></a> [infra](#module\_infra) | ./../../ | n/a |

## Resources

| Name | Type |
|------|------|
| [aws_ami.eks_node](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/data-sources/ami) | data source |

## Inputs

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|:--------:|
| <a name="input_additional_node_groups"></a> [additional\_node\_groups](#input\_additional\_node\_groups) | Additional EKS managed node groups definition. | `any` | n/a | yes |
| <a name="input_bastion"></a> [bastion](#input\_bastion) | enabled                  = Create bastion host.<br>    ami                      = Ami id. Defaults to latest 'amazon\_linux\_2' ami.<br>    instance\_type            = Instance type.<br>    authorized\_ssh\_ip\_ranges = List of CIDR ranges permitted for the bastion ssh access.<br>    username                 = Bastion user.<br>    install\_binaries         = Toggle to install required Domino binaries in the bastion. | `map(any)` | n/a | yes |
| <a name="input_default_node_groups"></a> [default\_node\_groups](#input\_default\_node\_groups) | EKS managed node groups definition. | `any` | n/a | yes |
| <a name="input_deploy_id"></a> [deploy\_id](#input\_deploy\_id) | Domino Deployment ID. | `string` | n/a | yes |
| <a name="input_eks"></a> [eks](#input\_eks) | k8s\_version = EKS cluster k8s version.<br>    kubeconfig = {<br>      extra\_args = Optional extra args when generating kubeconfig.<br>      path       = Fully qualified path name to write the kubeconfig file.<br>    }<br>    public\_access = {<br>      enabled = Enable EKS API public endpoint.<br>      cidrs   = List of CIDR ranges permitted for accessing the EKS public endpoint.<br>    }<br>    "Custom role maps for aws auth configmap<br>    custom\_role\_maps = {<br>      rolearn  = string<br>      username = string<br>      groups   = list(string)<br>    }<br>    master\_role\_names  = IAM role names to be added as masters in eks.<br>    cluster\_addons     = EKS cluster addons. vpc-cni is installed separately.<br>    vpc\_cni            = Configuration for AWS VPC CNI<br>    ssm\_log\_group\_name = CloudWatch log group to send the SSM session logs to.<br>    identity\_providers = Configuration for IDP(Identity Provider).<br>  } | `map(any)` | n/a | yes |
| <a name="input_k8s_version"></a> [k8s\_version](#input\_k8s\_version) | EKS cluster k8s version. | `string` | n/a | yes |
| <a name="input_kms"></a> [kms](#input\_kms) | enabled = Toggle,if set use either the specified KMS key\_id or a Domino-generated one.<br>    key\_id  = optional(string, null) | `map(any)` | n/a | yes |
| <a name="input_region"></a> [region](#input\_region) | AWS region for the deployment | `string` | n/a | yes |
| <a name="input_route53_hosted_zone_name"></a> [route53\_hosted\_zone\_name](#input\_route53\_hosted\_zone\_name) | Optional hosted zone for External DNS zone. | `string` | n/a | yes |
| <a name="input_ssh_pvt_key_path"></a> [ssh\_pvt\_key\_path](#input\_ssh\_pvt\_key\_path) | SSH private key filepath. | `string` | n/a | yes |
| <a name="input_tags"></a> [tags](#input\_tags) | Deployment tags. | `map(string)` | n/a | yes |

## Outputs

| Name | Description |
|------|-------------|
| <a name="output_infra"></a> [infra](#output\_infra) | Infrastructure outputs. |
<!-- END OF PRE-COMMIT-TERRAFORM DOCS HOOK -->
