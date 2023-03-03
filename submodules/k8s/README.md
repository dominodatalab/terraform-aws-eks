# k8s

<!-- BEGINNING OF PRE-COMMIT-TERRAFORM DOCS HOOK -->
## Requirements

| Name | Version |
|------|---------|
| <a name="requirement_terraform"></a> [terraform](#requirement\_terraform) | >= 1.0 |
| <a name="requirement_aws"></a> [aws](#requirement\_aws) | >= 4.0 |
| <a name="requirement_local"></a> [local](#requirement\_local) | >= 2.2.0 |
| <a name="requirement_null"></a> [null](#requirement\_null) | >= 3.1.0 |

## Providers

| Name | Version |
|------|---------|
| <a name="provider_local"></a> [local](#provider\_local) | >= 2.2.0 |
| <a name="provider_null"></a> [null](#provider\_null) | >= 3.1.0 |

## Modules

No modules.

## Resources

| Name | Type |
|------|------|
| [local_file.templates](https://registry.terraform.io/providers/hashicorp/local/latest/docs/resources/file) | resource |
| [null_resource.run_k8s_pre_setup](https://registry.terraform.io/providers/hashicorp/null/latest/docs/resources/resource) | resource |

## Inputs

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|:--------:|
| <a name="input_bastion_public_ip"></a> [bastion\_public\_ip](#input\_bastion\_public\_ip) | Bastion host public ip. | `string` | `""` | no |
| <a name="input_bastion_user"></a> [bastion\_user](#input\_bastion\_user) | ec2 instance user. | `string` | `"ec2-user"` | no |
| <a name="input_calico_version"></a> [calico\_version](#input\_calico\_version) | Calico operator version. | `string` | `"v3.25.0"` | no |
| <a name="input_eks_cluster_arn"></a> [eks\_cluster\_arn](#input\_eks\_cluster\_arn) | ARN of the EKS cluster | `string` | n/a | yes |
| <a name="input_eks_custom_role_maps"></a> [eks\_custom\_role\_maps](#input\_eks\_custom\_role\_maps) | Custom role maps for aws auth configmap | `list(object({ rolearn = string, username = string, groups = list(string) }))` | `[]` | no |
| <a name="input_eks_master_role_arns"></a> [eks\_master\_role\_arns](#input\_eks\_master\_role\_arns) | IAM role arns to be added as masters in eks. | `list(string)` | `[]` | no |
| <a name="input_eks_node_role_arns"></a> [eks\_node\_role\_arns](#input\_eks\_node\_role\_arns) | Roles arns for EKS nodes to be added to aws-auth for api auth. | `list(string)` | n/a | yes |
| <a name="input_k8s_tunnel_port"></a> [k8s\_tunnel\_port](#input\_k8s\_tunnel\_port) | K8s ssh tunnel port | `string` | `"1080"` | no |
| <a name="input_kubeconfig_path"></a> [kubeconfig\_path](#input\_kubeconfig\_path) | Kubeconfig filename. | `string` | `"kubeconfig"` | no |
| <a name="input_pod_subnets"></a> [pod\_subnets](#input\_pod\_subnets) | Pod subnets and az to setup with vpc-cni | `list(object({ subnet_id = string, az = string }))` | n/a | yes |
| <a name="input_security_group_id"></a> [security\_group\_id](#input\_security\_group\_id) | Security group id for eks cluster. | `string` | n/a | yes |
| <a name="input_ssh_pvt_key_path"></a> [ssh\_pvt\_key\_path](#input\_ssh\_pvt\_key\_path) | SSH private key filepath. | `string` | n/a | yes |

## Outputs

No outputs.
<!-- END OF PRE-COMMIT-TERRAFORM DOCS HOOK -->
