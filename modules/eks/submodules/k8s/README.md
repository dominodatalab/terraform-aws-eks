# k8s

<!-- BEGIN_TF_DOCS -->
## Requirements

| Name | Version |
|------|---------|
| <a name="requirement_terraform"></a> [terraform](#requirement\_terraform) | >= 1.0 |
| <a name="requirement_local"></a> [local](#requirement\_local) | >= 2.2.0 |
| <a name="requirement_null"></a> [null](#requirement\_null) | >= 3.1.0 |
| <a name="requirement_random"></a> [random](#requirement\_random) | >= 3.4.3 |

## Providers

| Name | Version |
|------|---------|
| <a name="provider_local"></a> [local](#provider\_local) | >= 2.2.0 |
| <a name="provider_random"></a> [random](#provider\_random) | >= 3.4.3 |

## Modules

No modules.

## Resources

| Name | Type |
|------|------|
| [local_file.templates](https://registry.terraform.io/providers/hashicorp/local/latest/docs/resources/file) | resource |
| [random_integer.port](https://registry.terraform.io/providers/hashicorp/random/latest/docs/resources/integer) | resource |

## Inputs

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|:--------:|
| <a name="input_bastion_info"></a> [bastion\_info](#input\_bastion\_info) | user                = Bastion username.<br/>    public\_ip           = Bastion public ip.<br/>    security\_group\_id   = Bastion sg id.<br/>    ssh\_bastion\_command = Command to ssh onto bastion. | <pre>object({<br/>    user                = string<br/>    public_ip           = string<br/>    security_group_id   = string<br/>    ssh_bastion_command = string<br/>  })</pre> | n/a | yes |
| <a name="input_cluster_name"></a> [cluster\_name](#input\_cluster\_name) | Name of EKS clsuter | `string` | `""` | no |
| <a name="input_eks_info"></a> [eks\_info](#input\_eks\_info) | cluster = {<br/>      version           = K8s version.<br/>      arn               = EKS Cluster arn.<br/>      security\_group\_id = EKS Cluster security group id.<br/>      endpoint          = EKS Cluster API endpoint.<br/>      roles             = Default IAM Roles associated with the EKS cluster. {<br/>        name = string<br/>        arn = string<br/>      }<br/>      custom\_roles      = Custom IAM Roles associated with the EKS cluster. {<br/>        rolearn  = string<br/>        username = string<br/>        groups   = list(string)<br/>      }<br/>      oidc = {<br/>        arn = OIDC provider ARN.<br/>        url = OIDC provider url.<br/>      }<br/>    }<br/>    nodes = {<br/>      security\_group\_id = EKS Nodes security group id.<br/>      roles = IAM Roles associated with the EKS Nodes.{<br/>        name = string<br/>        arn  = string<br/>      }<br/>    }<br/>    kubeconfig = Kubeconfig details.{<br/>      path       = string<br/>      extra\_args = string<br/>    }<br/>    calico = {<br/>      version = Configuration the version for Calico<br/>      image\_registry = Configure the image registry for Calico<br/>      node\_selector = Configure the node selector for Calico control plane components<br/>    } | <pre>object({<br/>    cluster = object({<br/>      version           = string<br/>      arn               = string<br/>      security_group_id = string<br/>      endpoint          = string<br/>      roles = list(object({<br/>        name = string<br/>        arn  = string<br/>      }))<br/>      custom_roles = list(object({<br/>        rolearn  = string<br/>        username = string<br/>        groups   = list(string)<br/>      }))<br/>      oidc = object({<br/>        arn = string<br/>        url = string<br/>      })<br/>    })<br/>    nodes = object({<br/>      nodes_master      = bool<br/>      security_group_id = string<br/>      roles = list(object({<br/>        name = string<br/>        arn  = string<br/>      }))<br/>    })<br/>    kubeconfig = object({<br/>      path       = string<br/>      extra_args = string<br/>    })<br/>    calico = object({<br/>      version        = string<br/>      image_registry = string<br/>      node_selector = object({<br/>        key   = string<br/>        value = string<br/>      })<br/>    })<br/>  })</pre> | n/a | yes |
| <a name="input_karpenter"></a> [karpenter](#input\_karpenter) | karpenter = {<br/>      enabled = Toggle installation of Karpenter.<br/>      namespace = Namespace to install Karpenter.<br/>      version = Configure the version for Karpenter.<br/>      delete\_instances\_on\_destroy = Toggle to delete Karpenter instances on destroy.<br/>      vm\_memory\_overhead\_percent  = Configure the vm memory overhead percent for Karpenter, represented in decimal form (%/100), i.e 7.5% = 0.075.<br/>      node\_selector = Configure the node selector for Karpenter components.<br/>    } | <pre>object({<br/>    enabled                     = bool<br/>    delete_instances_on_destroy = bool<br/>    namespace                   = string<br/>    version                     = string<br/>    vm_memory_overhead_percent  = optional(string, "0.075")<br/>    node_selector = object({<br/>      key   = string<br/>      value = string<br/>    })<br/>  })</pre> | n/a | yes |
| <a name="input_region"></a> [region](#input\_region) | Region of the EKS cluster | `string` | n/a | yes |
| <a name="input_ssh_key"></a> [ssh\_key](#input\_ssh\_key) | path          = SSH private key filepath.<br/>    key\_pair\_name = AWS key\_pair name. | <pre>object({<br/>    path          = string<br/>    key_pair_name = string<br/>  })</pre> | n/a | yes |
| <a name="input_use_fips_endpoint"></a> [use\_fips\_endpoint](#input\_use\_fips\_endpoint) | Use aws FIPS endpoints | `bool` | `false` | no |

## Outputs

| Name | Description |
|------|-------------|
| <a name="output_change_hash"></a> [change\_hash](#output\_change\_hash) | Hash of all templated files |
| <a name="output_filepath"></a> [filepath](#output\_filepath) | Filename of primary script |
| <a name="output_resources_directory"></a> [resources\_directory](#output\_resources\_directory) | Directory for provisioned scripts and templated files |
<!-- END_TF_DOCS -->
