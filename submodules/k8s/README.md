# k8s

<!-- BEGINNING OF PRE-COMMIT-TERRAFORM DOCS HOOK -->
## Requirements

| Name | Version |
|------|---------|
| <a name="requirement_terraform"></a> [terraform](#requirement\_terraform) | >= 1.0 |
| <a name="requirement_aws"></a> [aws](#requirement\_aws) | >= 4.0 |
| <a name="requirement_local"></a> [local](#requirement\_local) | >= 2.2.0 |
| <a name="requirement_null"></a> [null](#requirement\_null) | >= 3.1.0 |
| <a name="requirement_random"></a> [random](#requirement\_random) | >= 3.4.3 |

## Providers

| Name | Version |
|------|---------|
| <a name="provider_local"></a> [local](#provider\_local) | >= 2.2.0 |
| <a name="provider_null"></a> [null](#provider\_null) | >= 3.1.0 |
| <a name="provider_random"></a> [random](#provider\_random) | >= 3.4.3 |

## Modules

No modules.

## Resources

| Name | Type |
|------|------|
| [local_file.templates](https://registry.terraform.io/providers/hashicorp/local/latest/docs/resources/file) | resource |
| [null_resource.run_k8s_pre_setup](https://registry.terraform.io/providers/hashicorp/null/latest/docs/resources/resource) | resource |
| [random_integer.port](https://registry.terraform.io/providers/hashicorp/random/latest/docs/resources/integer) | resource |

## Inputs

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|:--------:|
| <a name="input_bastion_info"></a> [bastion\_info](#input\_bastion\_info) | user                = Bastion username.<br>    public\_ip           = Bastion public ip.<br>    security\_group\_id   = Bastion sg id.<br>    ssh\_bastion\_command = Command to ssh onto bastion. | <pre>object({<br>    user                = string<br>    public_ip           = string<br>    security_group_id   = string<br>    ssh_bastion_command = string<br>  })</pre> | n/a | yes |
| <a name="input_calico_version"></a> [calico\_version](#input\_calico\_version) | Calico operator version. | `string` | `"v3.25.0"` | no |
| <a name="input_eks_info"></a> [eks\_info](#input\_eks\_info) | cluster = {<br>      arn               = EKS Cluster arn.<br>      security\_group\_id = EKS Cluster security group id.<br>      endpoint          = EKS Cluster API endpoint.<br>      roles             = Default IAM Roles associated with the EKS cluster. {<br>        name = string<br>        arn = string<br>      }<br>      custom\_roles      = Custom IAM Roles associated with the EKS cluster. {<br>        rolearn  = string<br>        username = string<br>        groups   = list(string)<br>      }<br>    }<br>    nodes = {<br>      security\_group\_id = EKS Nodes security group id.<br>      roles = IAM Roles associated with the EKS Nodes.{<br>        name = string<br>        arn  = string<br>      }<br>    }<br>    kubeconfig = Kubeconfig details.{<br>      path       = string<br>      extra\_args = string<br>    } | <pre>object({<br>    cluster = object({<br>      arn               = string<br>      security_group_id = string<br>      endpoint          = string<br>      roles = list(object({<br>        name = string<br>        arn  = string<br>      }))<br>      custom_roles = list(object({<br>        rolearn  = string<br>        username = string<br>        groups   = list(string)<br>      }))<br>    })<br>    nodes = object({<br>      security_group_id = string<br>      roles = list(object({<br>        name = string<br>        arn  = string<br>      }))<br>    })<br>    kubeconfig = object({<br>      path       = string<br>      extra_args = string<br>    })<br>  })</pre> | n/a | yes |
| <a name="input_network_info"></a> [network\_info](#input\_network\_info) | id = VPC ID.<br>    subnets = {<br>      public = List of public Subnets.<br>      [{<br>        name = Subnet name.<br>        subnet\_id = Subnet ud<br>        az = Subnet availability\_zone<br>        az\_id = Subnet availability\_zone\_id<br>      }]<br>      private = List of private Subnets.<br>      [{<br>        name = Subnet name.<br>        subnet\_id = Subnet ud<br>        az = Subnet availability\_zone<br>        az\_id = Subnet availability\_zone\_id<br>      }]<br>      pod = List of pod Subnets.<br>      [{<br>        name = Subnet name.<br>        subnet\_id = Subnet ud<br>        az = Subnet availability\_zone<br>        az\_id = Subnet availability\_zone\_id<br>      }]<br>    } | <pre>object({<br>    vpc_id = string<br>    subnets = object({<br>      public = list(object({<br>        name      = string<br>        subnet_id = string<br>        az        = string<br>        az_id     = string<br>      }))<br>      private = optional(list(object({<br>        name      = string<br>        subnet_id = string<br>        az        = string<br>        az_id     = string<br>      })), [])<br>      pod = optional(list(object({<br>        name      = string<br>        subnet_id = string<br>        az        = string<br>        az_id     = string<br>      })), [])<br>    })<br>  })</pre> | n/a | yes |
| <a name="input_ssh_key"></a> [ssh\_key](#input\_ssh\_key) | path          = SSH private key filepath.<br>    key\_pair\_name = AWS key\_pair name. | <pre>object({<br>    path          = string<br>    key_pair_name = string<br>  })</pre> | n/a | yes |

## Outputs

No outputs.
<!-- END OF PRE-COMMIT-TERRAFORM DOCS HOOK -->
