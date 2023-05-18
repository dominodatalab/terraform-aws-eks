# eks

<!-- BEGINNING OF PRE-COMMIT-TERRAFORM DOCS HOOK -->
## Requirements

| Name | Version |
|------|---------|
| <a name="requirement_terraform"></a> [terraform](#requirement\_terraform) | >= 1.4.0 |
| <a name="requirement_aws"></a> [aws](#requirement\_aws) | >= 4.0 |
| <a name="requirement_null"></a> [null](#requirement\_null) | >= 3.1.0 |
| <a name="requirement_tls"></a> [tls](#requirement\_tls) | >= 4.0 |

## Providers

| Name | Version |
|------|---------|
| <a name="provider_aws"></a> [aws](#provider\_aws) | >= 4.0 |
| <a name="provider_null"></a> [null](#provider\_null) | >= 3.1.0 |
| <a name="provider_terraform"></a> [terraform](#provider\_terraform) | n/a |
| <a name="provider_tls"></a> [tls](#provider\_tls) | >= 4.0 |

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
| [aws_eks_identity_provider_config.this](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/eks_identity_provider_config) | resource |
| [aws_eks_node_group.node_groups](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/eks_node_group) | resource |
| [aws_iam_openid_connect_provider.oidc_provider](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/iam_openid_connect_provider) | resource |
| [aws_iam_policy.custom_eks_node_policy](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/iam_policy) | resource |
| [aws_iam_role.eks_cluster](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/iam_role) | resource |
| [aws_iam_role.eks_nodes](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/iam_role) | resource |
| [aws_iam_role_policy_attachment.aws_eks_nodes](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/iam_role_policy_attachment) | resource |
| [aws_iam_role_policy_attachment.custom_eks_nodes](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/iam_role_policy_attachment) | resource |
| [aws_iam_role_policy_attachment.eks_cluster](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/iam_role_policy_attachment) | resource |
| [aws_launch_template.node_groups](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/launch_template) | resource |
| [aws_security_group.eks_cluster](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/security_group) | resource |
| [aws_security_group.eks_nodes](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/security_group) | resource |
| [aws_security_group_rule.bastion_eks](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/security_group_rule) | resource |
| [aws_security_group_rule.efs](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/security_group_rule) | resource |
| [aws_security_group_rule.eks_cluster](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/security_group_rule) | resource |
| [aws_security_group_rule.node](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/security_group_rule) | resource |
| [null_resource.kubeconfig](https://registry.terraform.io/providers/hashicorp/null/latest/docs/resources/resource) | resource |
| [terraform_data.calico_setup](https://registry.terraform.io/providers/hashicorp/terraform/latest/docs/resources/data) | resource |
| [terraform_data.run_k8s_pre_setup](https://registry.terraform.io/providers/hashicorp/terraform/latest/docs/resources/data) | resource |
| [aws_ami.custom](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/data-sources/ami) | data source |
| [aws_caller_identity.aws_account](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/data-sources/caller_identity) | data source |
| [aws_ec2_instance_type_offerings.nodes](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/data-sources/ec2_instance_type_offerings) | data source |
| [aws_iam_policy_document.autoscaler](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/data-sources/iam_policy_document) | data source |
| [aws_iam_policy_document.custom_eks_node_policy](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/data-sources/iam_policy_document) | data source |
| [aws_iam_policy_document.ebs_csi](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/data-sources/iam_policy_document) | data source |
| [aws_iam_policy_document.eks_cluster](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/data-sources/iam_policy_document) | data source |
| [aws_iam_policy_document.eks_nodes](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/data-sources/iam_policy_document) | data source |
| [aws_iam_policy_document.snapshot](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/data-sources/iam_policy_document) | data source |
| [aws_iam_policy_document.ssm](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/data-sources/iam_policy_document) | data source |
| [aws_iam_role.master_roles](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/data-sources/iam_role) | data source |
| [aws_partition.current](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/data-sources/partition) | data source |
| [aws_ssm_parameter.eks_ami_release_version](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/data-sources/ssm_parameter) | data source |
| [aws_ssm_parameter.eks_gpu_ami_release_version](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/data-sources/ssm_parameter) | data source |
| [tls_certificate.cluster_tls_certificate](https://registry.terraform.io/providers/hashicorp/tls/latest/docs/data-sources/certificate) | data source |

## Inputs

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|:--------:|
| <a name="input_bastion_info"></a> [bastion\_info](#input\_bastion\_info) | user                = Bastion username.<br>    public\_ip           = Bastion public ip.<br>    security\_group\_id   = Bastion sg id.<br>    ssh\_bastion\_command = Command to ssh onto bastion. | <pre>object({<br>    user                = string<br>    public_ip           = string<br>    security_group_id   = string<br>    ssh_bastion_command = string<br>  })</pre> | n/a | yes |
| <a name="input_deploy_id"></a> [deploy\_id](#input\_deploy\_id) | Domino Deployment ID | `string` | n/a | yes |
| <a name="input_efs_security_group"></a> [efs\_security\_group](#input\_efs\_security\_group) | Security Group ID for EFS | `string` | n/a | yes |
| <a name="input_eks"></a> [eks](#input\_eks) | k8s\_version = EKS cluster k8s version.<br>    kubeconfig = {<br>      extra\_args = Optional extra args when generating kubeconfig.<br>      path       = Fully qualified path name to write the kubeconfig file. Defaults to '<current working directory>/kubeconfig'<br>    }<br>    public\_access = {<br>      enabled = Enable EKS API public endpoint.<br>      cidrs   = List of CIDR ranges permitted for accessing the EKS public endpoint.<br>    }<br>    List of Custom role maps for aws auth configmap<br>    custom\_role\_maps = [{<br>      rolearn = string<br>      username = string<br>      groups = list(string)<br>    }]<br>    master\_role\_names = IAM role names to be added as masters in EKS.<br>    cluster\_addons = EKS cluster addons. vpc-cni is installed separately.<br>    ssm\_log\_group\_name = "CloudWatch log group to send the SSM session logs to."<br>    identity\_providers = "Configuration for IDP(Identity Provider)." | <pre>object({<br>    k8s_version = optional(string)<br>    kubeconfig = optional(object({<br>      extra_args = optional(string)<br>      path       = optional(string)<br>    }))<br>    public_access = optional(object({<br>      enabled = optional(bool)<br>      cidrs   = optional(list(string))<br>    }))<br>    custom_role_maps = optional(list(object({<br>      rolearn  = string<br>      username = string<br>      groups   = list(string)<br>    })))<br>    master_role_names  = optional(list(string))<br>    cluster_addons     = optional(list(string))<br>    ssm_log_group_name = optional(string)<br>    identity_providers = optional(list(object({<br>      client_id                     = string<br>      groups_claim                  = optional(string, null)<br>      groups_prefix                 = optional(string, null)<br>      identity_provider_config_name = string<br>      issuer_url                    = optional(string, null)<br>      required_claims               = optional(string, null)<br>      username_claim                = optional(string, null)<br>      username_prefix               = optional(string, null)<br>    })), [])<br>  })</pre> | n/a | yes |
| <a name="input_kms_info"></a> [kms\_info](#input\_kms\_info) | key\_id  = KMS key id.<br>    key\_arn = KMS key arn.<br>    enabled = KMS key is enabled | <pre>object({<br>    key_id  = string<br>    key_arn = string<br>    enabled = bool<br>  })</pre> | n/a | yes |
| <a name="input_network_info"></a> [network\_info](#input\_network\_info) | id = VPC ID.<br>    subnets = {<br>      public = List of public Subnets.<br>      [{<br>        name = Subnet name.<br>        subnet\_id = Subnet ud<br>        az = Subnet availability\_zone<br>        az\_id = Subnet availability\_zone\_id<br>      }]<br>      private = List of private Subnets.<br>      [{<br>        name = Subnet name.<br>        subnet\_id = Subnet ud<br>        az = Subnet availability\_zone<br>        az\_id = Subnet availability\_zone\_id<br>      }]<br>      pod = List of pod Subnets.<br>      [{<br>        name = Subnet name.<br>        subnet\_id = Subnet ud<br>        az = Subnet availability\_zone<br>        az\_id = Subnet availability\_zone\_id<br>      }]<br>    } | <pre>object({<br>    vpc_id = string<br>    subnets = object({<br>      public = list(object({<br>        name      = string<br>        subnet_id = string<br>        az        = string<br>        az_id     = string<br>      }))<br>      private = list(object({<br>        name      = string<br>        subnet_id = string<br>        az        = string<br>        az_id     = string<br>      }))<br>      pod = list(object({<br>        name      = string<br>        subnet_id = string<br>        az        = string<br>        az_id     = string<br>      }))<br>    })<br>  })</pre> | n/a | yes |
| <a name="input_node_groups"></a> [node\_groups](#input\_node\_groups) | EKS managed node groups definition. | <pre>map(object({<br>    ami                   = optional(string, null)<br>    bootstrap_extra_args  = optional(string, "")<br>    instance_types        = list(string)<br>    spot                  = optional(bool, false)<br>    min_per_az            = number<br>    max_per_az            = number<br>    desired_per_az        = number<br>    availability_zone_ids = list(string)<br>    labels                = map(string)<br>    taints                = optional(list(object({ key = string, value = optional(string), effect = string })), [])<br>    tags                  = optional(map(string), {})<br>    instance_tags         = optional(map(string), {})<br>    gpu                   = optional(bool, false)<br>    volume = object({<br>      size = string<br>      type = string<br>    })<br>  }))</pre> | n/a | yes |
| <a name="input_node_iam_policies"></a> [node\_iam\_policies](#input\_node\_iam\_policies) | Additional IAM Policy Arns for Nodes | `list(string)` | n/a | yes |
| <a name="input_region"></a> [region](#input\_region) | AWS region for the deployment | `string` | n/a | yes |
| <a name="input_ssh_key"></a> [ssh\_key](#input\_ssh\_key) | path          = SSH private key filepath.<br>    key\_pair\_name = AWS key\_pair name. | <pre>object({<br>    path          = string<br>    key_pair_name = string<br>  })</pre> | n/a | yes |

## Outputs

| Name | Description |
|------|-------------|
| <a name="output_info"></a> [info](#output\_info) | EKS information |
<!-- END OF PRE-COMMIT-TERRAFORM DOCS HOOK -->
