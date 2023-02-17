# eks

<!-- BEGINNING OF PRE-COMMIT-TERRAFORM DOCS HOOK -->
## Requirements

| Name | Version |
|------|---------|
| <a name="requirement_terraform"></a> [terraform](#requirement\_terraform) | >= 1.3.0 |
| <a name="requirement_aws"></a> [aws](#requirement\_aws) | >= 4.0 |
| <a name="requirement_null"></a> [null](#requirement\_null) | >= 3.1.0 |

## Providers

| Name | Version |
|------|---------|
| <a name="provider_aws"></a> [aws](#provider\_aws) | >= 4.0 |
| <a name="provider_null"></a> [null](#provider\_null) | >= 3.1.0 |

## Modules

| Name | Source | Version |
|------|--------|---------|
| <a name="module_k8s_setup"></a> [k8s\_setup](#module\_k8s\_setup) | ../k8s | n/a |

## Resources

| Name | Type |
|------|------|
| [aws_autoscaling_group_tag.tag](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/autoscaling_group_tag) | resource |
| [aws_cloudwatch_log_group.eks_cluster](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/cloudwatch_log_group) | resource |
| [aws_eks_addon.this](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/eks_addon) | resource |
| [aws_eks_addon.vpc_cni](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/eks_addon) | resource |
| [aws_eks_cluster.this](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/eks_cluster) | resource |
| [aws_eks_node_group.node_groups](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/eks_node_group) | resource |
| [aws_iam_policy.custom_eks_node_policy](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/iam_policy) | resource |
| [aws_iam_role.eks_cluster](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/iam_role) | resource |
| [aws_iam_role.eks_nodes](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/iam_role) | resource |
| [aws_iam_role_policy_attachment.aws_eks_nodes](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/iam_role_policy_attachment) | resource |
| [aws_iam_role_policy_attachment.custom_eks_nodes](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/iam_role_policy_attachment) | resource |
| [aws_iam_role_policy_attachment.eks_cluster](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/iam_role_policy_attachment) | resource |
| [aws_kms_key.eks_cluster](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/kms_key) | resource |
| [aws_launch_template.node_groups](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/launch_template) | resource |
| [aws_security_group.eks_cluster](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/security_group) | resource |
| [aws_security_group.eks_nodes](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/security_group) | resource |
| [aws_security_group_rule.bastion_eks](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/security_group_rule) | resource |
| [aws_security_group_rule.efs](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/security_group_rule) | resource |
| [aws_security_group_rule.eks_cluster](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/security_group_rule) | resource |
| [aws_security_group_rule.node](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/security_group_rule) | resource |
| [null_resource.kubeconfig](https://registry.terraform.io/providers/hashicorp/null/latest/docs/resources/resource) | resource |
| [aws_caller_identity.aws_account](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/data-sources/caller_identity) | data source |
| [aws_default_tags.this](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/data-sources/default_tags) | data source |
| [aws_iam_policy_document.autoscaler](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/data-sources/iam_policy_document) | data source |
| [aws_iam_policy_document.custom_eks_node_policy](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/data-sources/iam_policy_document) | data source |
| [aws_iam_policy_document.ebs_csi](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/data-sources/iam_policy_document) | data source |
| [aws_iam_policy_document.eks_cluster](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/data-sources/iam_policy_document) | data source |
| [aws_iam_policy_document.eks_nodes](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/data-sources/iam_policy_document) | data source |
| [aws_iam_policy_document.kms_key](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/data-sources/iam_policy_document) | data source |
| [aws_iam_policy_document.snapshot](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/data-sources/iam_policy_document) | data source |
| [aws_iam_role.eks_master_roles](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/data-sources/iam_role) | data source |
| [aws_partition.current](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/data-sources/partition) | data source |
| [aws_ssm_parameter.eks_ami_release_version](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/data-sources/ssm_parameter) | data source |
| [aws_ssm_parameter.eks_gpu_ami_release_version](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/data-sources/ssm_parameter) | data source |

## Inputs

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|:--------:|
| <a name="input_bastion_public_ip"></a> [bastion\_public\_ip](#input\_bastion\_public\_ip) | Public IP of bastion instance | `string` | `""` | no |
| <a name="input_bastion_security_group_id"></a> [bastion\_security\_group\_id](#input\_bastion\_security\_group\_id) | Bastion security group id. | `string` | `""` | no |
| <a name="input_bastion_user"></a> [bastion\_user](#input\_bastion\_user) | Username for bastion instance | `string` | `""` | no |
| <a name="input_create_bastion_sg"></a> [create\_bastion\_sg](#input\_create\_bastion\_sg) | Create bastion access rules toggle. | `bool` | `false` | no |
| <a name="input_deploy_id"></a> [deploy\_id](#input\_deploy\_id) | Domino Deployment ID | `string` | n/a | yes |
| <a name="input_efs_security_group"></a> [efs\_security\_group](#input\_efs\_security\_group) | Security Group ID for EFS | `string` | n/a | yes |
| <a name="input_eks_cluster_addons"></a> [eks\_cluster\_addons](#input\_eks\_cluster\_addons) | EKS cluster addons. vpc-cni is installed separately. | `list(string)` | <pre>[<br>  "kube-proxy",<br>  "coredns"<br>]</pre> | no |
| <a name="input_eks_custom_role_maps"></a> [eks\_custom\_role\_maps](#input\_eks\_custom\_role\_maps) | Custom role maps for aws auth configmap | `list(object({ rolearn = string, username = string, groups = list(string) }))` | `[]` | no |
| <a name="input_eks_master_role_names"></a> [eks\_master\_role\_names](#input\_eks\_master\_role\_names) | IAM role names to be added as masters in eks | `list(string)` | `[]` | no |
| <a name="input_k8s_version"></a> [k8s\_version](#input\_k8s\_version) | EKS cluster k8s version. | `string` | n/a | yes |
| <a name="input_kubeconfig_path"></a> [kubeconfig\_path](#input\_kubeconfig\_path) | Kubeconfig file path. | `string` | `"kubeconfig"` | no |
| <a name="input_node_groups"></a> [node\_groups](#input\_node\_groups) | Additional EKS managed node groups definition. | <pre>map(object({<br>    ami                  = optional(string, null)<br>    bootstrap_extra_args = optional(string, "")<br>    instance_types       = list(string)<br>    spot                 = optional(bool, false)<br>    min_per_az           = number<br>    max_per_az           = number<br>    desired_per_az       = number<br>    labels               = map(string)<br>    taints               = optional(list(object({ key = string, value = optional(string), effect = string })), [])<br>    tags                 = optional(map(string), {})<br>    instance_tags        = optional(map(string), {})<br>    gpu                  = optional(bool, false)<br>    volume = object({<br>      size = string<br>      type = string<br>    })<br>  }))</pre> | `{}` | no |
| <a name="input_node_groups_kms_key"></a> [node\_groups\_kms\_key](#input\_node\_groups\_kms\_key) | if set, use specified key for the EKS node groups | `string` | `null` | no |
| <a name="input_node_iam_policies"></a> [node\_iam\_policies](#input\_node\_iam\_policies) | Additional IAM Policy Arns for Nodes | `list(string)` | n/a | yes |
| <a name="input_pod_subnets"></a> [pod\_subnets](#input\_pod\_subnets) | List of POD subnets IDs and AZ | `list(object({ subnet_id = string, az = string }))` | n/a | yes |
| <a name="input_private_subnets"></a> [private\_subnets](#input\_private\_subnets) | List of Private subnets IDs and AZ | `list(object({ subnet_id = string, az = string }))` | n/a | yes |
| <a name="input_region"></a> [region](#input\_region) | AWS region for the deployment | `string` | n/a | yes |
| <a name="input_secrets_kms_key"></a> [secrets\_kms\_key](#input\_secrets\_kms\_key) | if set, use specified key for the EKS cluster secrets | `string` | `null` | no |
| <a name="input_ssh_key_pair_name"></a> [ssh\_key\_pair\_name](#input\_ssh\_key\_pair\_name) | SSH key pair name. | `string` | n/a | yes |
| <a name="input_ssh_pvt_key_path"></a> [ssh\_pvt\_key\_path](#input\_ssh\_pvt\_key\_path) | Path to SSH private key | `string` | `""` | no |
| <a name="input_update_kubeconfig_extra_args"></a> [update\_kubeconfig\_extra\_args](#input\_update\_kubeconfig\_extra\_args) | Optional extra args when generating kubeconfig | `string` | `""` | no |
| <a name="input_vpc_id"></a> [vpc\_id](#input\_vpc\_id) | VPC ID. | `string` | n/a | yes |

## Outputs

| Name | Description |
|------|-------------|
| <a name="output_cluster_endpoint"></a> [cluster\_endpoint](#output\_cluster\_endpoint) | EKS cluster API endpoint. |
| <a name="output_eks_master_roles"></a> [eks\_master\_roles](#output\_eks\_master\_roles) | EKS master roles. |
| <a name="output_eks_node_roles"></a> [eks\_node\_roles](#output\_eks\_node\_roles) | EKS managed node roles |
| <a name="output_nodes_security_group_id"></a> [nodes\_security\_group\_id](#output\_nodes\_security\_group\_id) | EKS managed nodes security group id. |
| <a name="output_security_group_id"></a> [security\_group\_id](#output\_security\_group\_id) | EKS security group id. |
<!-- END OF PRE-COMMIT-TERRAFORM DOCS HOOK -->
