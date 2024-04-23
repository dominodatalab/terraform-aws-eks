# nodes

<!-- BEGINNING OF PRE-COMMIT-TERRAFORM DOCS HOOK -->
## Requirements

| Name | Version |
|------|---------|
| <a name="requirement_terraform"></a> [terraform](#requirement\_terraform) | >= 1.7.0 |
| <a name="requirement_aws"></a> [aws](#requirement\_aws) | ~> 5.0 |
| <a name="requirement_null"></a> [null](#requirement\_null) | >= 3.1.0 |
| <a name="requirement_tls"></a> [tls](#requirement\_tls) | >= 4.0 |

## Providers

| Name | Version |
|------|---------|
| <a name="provider_aws"></a> [aws](#provider\_aws) | ~> 5.0 |
| <a name="provider_terraform"></a> [terraform](#provider\_terraform) | n/a |

## Modules

No modules.

## Resources

| Name | Type |
|------|------|
| [aws_eip.single_node](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/eip) | resource |
| [aws_eip_association.single_node](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/eip_association) | resource |
| [aws_eks_addon.post_compute_addons](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/eks_addon) | resource |
| [aws_eks_addon.pre_compute_addons](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/eks_addon) | resource |
| [aws_iam_instance_profile.single_node](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/iam_instance_profile) | resource |
| [aws_instance.single_node](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/instance) | resource |
| [aws_launch_template.single_node](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/launch_template) | resource |
| [aws_security_group.single_node](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/security_group) | resource |
| [aws_security_group_rule.single_node](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/security_group_rule) | resource |
| [terraform_data.calico_setup](https://registry.terraform.io/providers/hashicorp/terraform/latest/docs/resources/data) | resource |
| [terraform_data.node_is_ready](https://registry.terraform.io/providers/hashicorp/terraform/latest/docs/resources/data) | resource |
| [aws_ami.single_node](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/data-sources/ami) | data source |
| [aws_default_tags.this](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/data-sources/default_tags) | data source |
| [aws_eks_addon_version.default](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/data-sources/eks_addon_version) | data source |

## Inputs

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|:--------:|
| <a name="input_eks_info"></a> [eks\_info](#input\_eks\_info) | cluster = {<br>      addons            = List of addons<br>      specs             = Cluster spes. {<br>        name                      = Cluster name.<br>        endpoint                  = Cluster endpont.<br>        kubernetes\_network\_config = Cluster k8s nw config.<br>      }<br>      version           = K8s version.<br>      arn               = EKS Cluster arn.<br>      security\_group\_id = EKS Cluster security group id.<br>      endpoint          = EKS Cluster API endpoint.<br>      roles             = Default IAM Roles associated with the EKS cluster. {<br>        name = string<br>        arn = string<br>      }<br>      custom\_roles      = Custom IAM Roles associated with the EKS cluster. {<br>        rolearn  = string<br>        username = string<br>        groups   = list(string)<br>      }<br>      oidc = {<br>        arn = OIDC provider ARN.<br>        url = OIDC provider url.<br>      }<br>    }<br>    nodes = {<br>      security\_group\_id = EKS Nodes security group id.<br>      roles = IAM Roles associated with the EKS Nodes.{<br>        name = string<br>        arn  = string<br>      }<br>    }<br>    kubeconfig = Kubeconfig details.{<br>      path       = string<br>      extra\_args = string<br>    } | <pre>object({<br>    k8s_pre_setup_sh_file = string<br>    cluster = object({<br>      addons = optional(list(string), ["kube-proxy", "coredns", "vpc-cni"])<br>      vpc_cni = optional(object({<br>        prefix_delegation = optional(bool, false)<br>        annotate_pod_ip   = optional(bool, true)<br>      }))<br>      specs = object({<br>        name                      = string<br>        endpoint                  = string<br>        kubernetes_network_config = list(map(any))<br>        certificate_authority     = list(map(any))<br>      })<br>      version           = string<br>      arn               = string<br>      security_group_id = string<br>      endpoint          = string<br>      roles = list(object({<br>        name = string<br>        arn  = string<br>      }))<br>      custom_roles = list(object({<br>        rolearn  = string<br>        username = string<br>        groups   = list(string)<br>      }))<br>      oidc = object({<br>        arn = string<br>        url = string<br>      })<br>    })<br>    nodes = object({<br>      security_group_id = string<br>      roles = list(object({<br>        name = string<br>        arn  = string<br>      }))<br>    })<br>    kubeconfig = object({<br>      path       = string<br>      extra_args = string<br>    })<br>  })</pre> | n/a | yes |
| <a name="input_kms_info"></a> [kms\_info](#input\_kms\_info) | key\_id  = KMS key id.<br>    key\_arn = KMS key arn.<br>    enabled = KMS key is enabled | <pre>object({<br>    key_id  = string<br>    key_arn = string<br>    enabled = bool<br>  })</pre> | n/a | yes |
| <a name="input_network_info"></a> [network\_info](#input\_network\_info) | id = VPC ID.<br>    subnets = {<br>      public = List of public Subnets.<br>      [{<br>        name = Subnet name.<br>        subnet\_id = Subnet ud<br>        az = Subnet availability\_zone<br>        az\_id = Subnet availability\_zone\_id<br>      }]<br>      private = List of private Subnets.<br>      [{<br>        name = Subnet name.<br>        subnet\_id = Subnet ud<br>        az = Subnet availability\_zone<br>        az\_id = Subnet availability\_zone\_id<br>      }]<br>      pod = List of pod Subnets.<br>      [{<br>        name = Subnet name.<br>        subnet\_id = Subnet ud<br>        az = Subnet availability\_zone<br>        az\_id = Subnet availability\_zone\_id<br>      }]<br>    } | <pre>object({<br>    vpc_id = string<br>    subnets = object({<br>      public = list(object({<br>        name      = string<br>        subnet_id = string<br>        az        = string<br>        az_id     = string<br>      }))<br>      private = optional(list(object({<br>        name      = string<br>        subnet_id = string<br>        az        = string<br>        az_id     = string<br>      })), [])<br>      pod = optional(list(object({<br>        name      = string<br>        subnet_id = string<br>        az        = string<br>        az_id     = string<br>      })), [])<br>    })<br>  })</pre> | n/a | yes |
| <a name="input_region"></a> [region](#input\_region) | AWS region for the deployment | `string` | n/a | yes |
| <a name="input_run_post_node_setup"></a> [run\_post\_node\_setup](#input\_run\_post\_node\_setup) | Toggle installing addons and calico | `bool` | `true` | no |
| <a name="input_single_node"></a> [single\_node](#input\_single\_node) | Additional EKS managed node groups definition. | <pre>object({<br>    name                 = optional(string, "single-node")<br>    bootstrap_extra_args = optional(string, "")<br>    ami = optional(object({<br>      name_prefix = optional(string, null)<br>      owner       = optional(string, null)<br><br>    }))<br>    instance_type            = optional(string, "m6i.2xlarge")<br>    authorized_ssh_ip_ranges = optional(list(string), ["0.0.0.0/0"])<br>    labels                   = optional(map(string))<br>    taints = optional(list(object({<br>      key    = string<br>      value  = optional(string)<br>      effect = string<br>    })), [])<br>    volume = optional(object({<br>      size = optional(number, 200)<br>      type = optional(string, "gp3")<br>    }), {})<br>  })</pre> | `{}` | no |
| <a name="input_ssh_key"></a> [ssh\_key](#input\_ssh\_key) | path          = SSH private key filepath.<br>    key\_pair\_name = AWS key\_pair name. | <pre>object({<br>    path          = string<br>    key_pair_name = string<br>  })</pre> | n/a | yes |

## Outputs

| Name | Description |
|------|-------------|
| <a name="output_info"></a> [info](#output\_info) | Node details. |
<!-- END OF PRE-COMMIT-TERRAFORM DOCS HOOK -->
