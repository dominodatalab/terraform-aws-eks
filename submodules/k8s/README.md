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
| <a name="input_bastion_public_ip"></a> [bastion\_public\_ip](#input\_bastion\_public\_ip) | Bastion host public ip. | `string` | n/a | yes |
| <a name="input_bastion_user"></a> [bastion\_user](#input\_bastion\_user) | ec2 instance user. | `string` | `"ec2-user"` | no |
| <a name="input_calico_version"></a> [calico\_version](#input\_calico\_version) | Calico operator version. | `string` | `"v1.11.0"` | no |
| <a name="input_eks_master_role_arns"></a> [eks\_master\_role\_arns](#input\_eks\_master\_role\_arns) | IAM role arns to be added as masters in eks. | `list(string)` | `[]` | no |
| <a name="input_eks_node_role_arns"></a> [eks\_node\_role\_arns](#input\_eks\_node\_role\_arns) | Roles arns for EKS nodes to be added to aws-auth for api auth. | `list(string)` | n/a | yes |
| <a name="input_k8s_cluster_endpoint"></a> [k8s\_cluster\_endpoint](#input\_k8s\_cluster\_endpoint) | EKS cluster API endpoint. | `string` | n/a | yes |
| <a name="input_kubeconfig_path"></a> [kubeconfig\_path](#input\_kubeconfig\_path) | Kubeconfig filename. | `string` | `"kubeconfig"` | no |
| <a name="input_mallory_local_normal_port"></a> [mallory\_local\_normal\_port](#input\_mallory\_local\_normal\_port) | Mallory k8s tunnel normal port. | `string` | `"1315"` | no |
| <a name="input_mallory_local_smart_port"></a> [mallory\_local\_smart\_port](#input\_mallory\_local\_smart\_port) | Mallory k8s tunnel smart(filters based on the blocked list) port. | `string` | `"1316"` | no |
| <a name="input_ssh_pvt_key_path"></a> [ssh\_pvt\_key\_path](#input\_ssh\_pvt\_key\_path) | SSH private key filepath. | `string` | n/a | yes |

## Outputs

| Name | Description |
|------|-------------|
| <a name="output_k8s_tunnel_command"></a> [k8s\_tunnel\_command](#output\_k8s\_tunnel\_command) | Command to run the k8s tunnel mallory. |
<!-- END OF PRE-COMMIT-TERRAFORM DOCS HOOK -->
