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
| <a name="input_bastion_info"></a> [bastion\_info](#input\_bastion\_info) | user                = Bastion username.<br>    public\_ip           = Bastion public ip.<br>    security\_group\_id   = Bastion sg id.<br>    ssh\_bastion\_command = Command to ssh onto bastion. | <pre>object({<br>    user                = string<br>    public_ip           = string<br>    security_group_id   = string<br>    ssh_bastion_command = string<br>  })</pre> | `null` | no |
| <a name="input_calico_version"></a> [calico\_version](#input\_calico\_version) | Calico operator version. | `string` | `"v3.25.0"` | no |
| <a name="input_eks_cluster_arn"></a> [eks\_cluster\_arn](#input\_eks\_cluster\_arn) | ARN of the EKS cluster | `string` | n/a | yes |
| <a name="input_eks_custom_role_maps"></a> [eks\_custom\_role\_maps](#input\_eks\_custom\_role\_maps) | Custom role maps for aws auth configmap | `list(object({ rolearn = string, username = string, groups = list(string) }))` | `[]` | no |
| <a name="input_eks_master_role_arns"></a> [eks\_master\_role\_arns](#input\_eks\_master\_role\_arns) | IAM role arns to be added as masters in eks. | `list(string)` | `[]` | no |
| <a name="input_eks_node_role_arns"></a> [eks\_node\_role\_arns](#input\_eks\_node\_role\_arns) | Roles arns for EKS nodes to be added to aws-auth for api auth. | `list(string)` | n/a | yes |
| <a name="input_k8s_tunnel_port"></a> [k8s\_tunnel\_port](#input\_k8s\_tunnel\_port) | K8s ssh tunnel port | `string` | `"1080"` | no |
| <a name="input_kubeconfig_path"></a> [kubeconfig\_path](#input\_kubeconfig\_path) | Kubeconfig filename. | `string` | `"kubeconfig"` | no |
| <a name="input_network_info"></a> [network\_info](#input\_network\_info) | id = VPC ID.<br>    subnets = {<br>      public = List of public Subnets.<br>      [{<br>        name = Subnet name.<br>        subnet\_id = Subnet ud<br>        az = Subnet availability\_zone<br>        az\_id = Subnet availability\_zone\_id<br>      }]<br>      private = List of private Subnets.<br>      [{<br>        name = Subnet name.<br>        subnet\_id = Subnet ud<br>        az = Subnet availability\_zone<br>        az\_id = Subnet availability\_zone\_id<br>      }]<br>      pod = List of pod Subnets.<br>      [{<br>        name = Subnet name.<br>        subnet\_id = Subnet ud<br>        az = Subnet availability\_zone<br>        az\_id = Subnet availability\_zone\_id<br>      }]<br>    } | <pre>object({<br>    vpc_id = string<br>    subnets = object({<br>      public = list(object({<br>        name      = string<br>        subnet_id = string<br>        az        = string<br>        az_id     = string<br>      }))<br>      private = optional(list(object({<br>        name      = string<br>        subnet_id = string<br>        az        = string<br>        az_id     = string<br>      })), [])<br>      pod = optional(list(object({<br>        name      = string<br>        subnet_id = string<br>        az        = string<br>        az_id     = string<br>      })), [])<br>    })<br>  })</pre> | n/a | yes |
| <a name="input_security_group_id"></a> [security\_group\_id](#input\_security\_group\_id) | Security group id for eks cluster. | `string` | n/a | yes |
| <a name="input_ssh_key"></a> [ssh\_key](#input\_ssh\_key) | path          = SSH private key filepath.<br>    key\_pair\_name = AWS key\_pair name. | <pre>object({<br>    path          = string<br>    key_pair_name = string<br>  })</pre> | n/a | yes |

## Outputs

No outputs.
<!-- END OF PRE-COMMIT-TERRAFORM DOCS HOOK -->
