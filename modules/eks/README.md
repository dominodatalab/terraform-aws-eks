# eks

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
| <a name="provider_aws.eks"></a> [aws.eks](#provider\_aws.eks) | ~> 5.0 |
| <a name="provider_null"></a> [null](#provider\_null) | >= 3.1.0 |
| <a name="provider_terraform"></a> [terraform](#provider\_terraform) | n/a |
| <a name="provider_tls"></a> [tls](#provider\_tls) | >= 4.0 |

## Modules

| Name | Source | Version |
|------|--------|---------|
| <a name="module_k8s_setup"></a> [k8s\_setup](#module\_k8s\_setup) | ./submodules/k8s | n/a |
| <a name="module_privatelink"></a> [privatelink](#module\_privatelink) | ./submodules/privatelink | n/a |

## Resources

| Name | Type |
|------|------|
| [aws_cloudwatch_log_group.eks_cluster](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/cloudwatch_log_group) | resource |
| [aws_eks_cluster.this](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/eks_cluster) | resource |
| [aws_eks_identity_provider_config.this](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/eks_identity_provider_config) | resource |
| [aws_iam_openid_connect_provider.oidc_provider](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/iam_openid_connect_provider) | resource |
| [aws_iam_policy.custom_eks_node_policy](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/iam_policy) | resource |
| [aws_iam_role.eks_auto_node_role](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/iam_role) | resource |
| [aws_iam_role.eks_cluster](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/iam_role) | resource |
| [aws_iam_role.eks_nodes](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/iam_role) | resource |
| [aws_iam_role_policy_attachment.aws_auto_eks_nodes](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/iam_role_policy_attachment) | resource |
| [aws_iam_role_policy_attachment.aws_eks_nodes](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/iam_role_policy_attachment) | resource |
| [aws_iam_role_policy_attachment.custom_eks_nodes](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/iam_role_policy_attachment) | resource |
| [aws_iam_role_policy_attachment.eks_cluster](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/iam_role_policy_attachment) | resource |
| [aws_security_group.eks_cluster](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/security_group) | resource |
| [aws_security_group.eks_nodes](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/security_group) | resource |
| [aws_security_group_rule.bastion_eks](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/security_group_rule) | resource |
| [aws_security_group_rule.ecr_endpoint](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/security_group_rule) | resource |
| [aws_security_group_rule.efs](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/security_group_rule) | resource |
| [aws_security_group_rule.eks_cluster](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/security_group_rule) | resource |
| [aws_security_group_rule.netapp](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/security_group_rule) | resource |
| [aws_security_group_rule.node](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/security_group_rule) | resource |
| [null_resource.kubeconfig](https://registry.terraform.io/providers/hashicorp/null/latest/docs/resources/resource) | resource |
| [terraform_data.run_k8s_pre_setup](https://registry.terraform.io/providers/hashicorp/terraform/latest/docs/resources/data) | resource |
| [aws_caller_identity.aws_account](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/data-sources/caller_identity) | data source |
| [aws_caller_identity.aws_eks_provider](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/data-sources/caller_identity) | data source |
| [aws_caller_identity.cluster_aws_account](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/data-sources/caller_identity) | data source |
| [aws_iam_policy_document.auto_node_trust_policy](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/data-sources/iam_policy_document) | data source |
| [aws_iam_policy_document.autoscaler](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/data-sources/iam_policy_document) | data source |
| [aws_iam_policy_document.custom_eks_node_policy](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/data-sources/iam_policy_document) | data source |
| [aws_iam_policy_document.ebs_csi](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/data-sources/iam_policy_document) | data source |
| [aws_iam_policy_document.eks_cluster](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/data-sources/iam_policy_document) | data source |
| [aws_iam_policy_document.eks_nodes](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/data-sources/iam_policy_document) | data source |
| [aws_iam_policy_document.snapshot](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/data-sources/iam_policy_document) | data source |
| [aws_iam_policy_document.ssm](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/data-sources/iam_policy_document) | data source |
| [aws_iam_role.master_roles](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/data-sources/iam_role) | data source |
| [aws_iam_session_context.create_eks_role](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/data-sources/iam_session_context) | data source |
| [aws_partition.current](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/data-sources/partition) | data source |
| [tls_certificate.cluster_tls_certificate](https://registry.terraform.io/providers/hashicorp/tls/latest/docs/data-sources/certificate) | data source |

## Inputs

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|:--------:|
| <a name="input_bastion_info"></a> [bastion\_info](#input\_bastion\_info) | user                = Bastion username.<br>    public\_ip           = Bastion public ip.<br>    security\_group\_id   = Bastion sg id.<br>    ssh\_bastion\_command = Command to ssh onto bastion. | <pre>object({<br>    user                = string<br>    public_ip           = string<br>    security_group_id   = string<br>    ssh_bastion_command = string<br>  })</pre> | n/a | yes |
| <a name="input_calico"></a> [calico](#input\_calico) | calico = {<br>      version = Configure the version for Calico<br>      image\_registry = Configure the image registry for Calico<br>    } | <pre>object({<br>    image_registry = optional(string, "quay.io")<br>    version        = optional(string, "v3.28.2")<br>  })</pre> | `{}` | no |
| <a name="input_create_eks_role_arn"></a> [create\_eks\_role\_arn](#input\_create\_eks\_role\_arn) | Role arn to assume during the EKS cluster creation. | `string` | n/a | yes |
| <a name="input_deploy_id"></a> [deploy\_id](#input\_deploy\_id) | Domino Deployment ID | `string` | n/a | yes |
| <a name="input_eks"></a> [eks](#input\_eks) | service\_ipv4\_cidr = CIDR for EKS cluster kubernetes\_network\_config.<br>    creation\_role\_name = Name of the role to import.<br>    k8s\_version = EKS cluster k8s version.<br>    nodes\_master  Grants the nodes role system:master access. NOT recomended<br>    kubeconfig = {<br>      extra\_args = Optional extra args when generating kubeconfig.<br>      path       = Fully qualified path name to write the kubeconfig file.<br>    }<br>    public\_access = {<br>      enabled = Enable EKS API public endpoint.<br>      cidrs   = List of CIDR ranges permitted for accessing the EKS public endpoint.<br>    }<br>    Custom role maps for aws auth configmap<br>    custom\_role\_maps = {<br>      rolearn = string<br>      username = string<br>      groups = list(string)<br>    }<br>    master\_role\_names = IAM role names to be added as masters in eks.<br>    cluster\_addons = EKS cluster addons. vpc-cni is installed separately.<br>    vpc\_cni = Configuration for AWS VPC CNI<br>    ssm\_log\_group\_name = CloudWatch log group to send the SSM session logs to.<br>    identity\_providers = Configuration for IDP(Identity Provider).<br>  } | <pre>object({<br>    auto_mode_enabled   = optional(bool, true)<br>    authentication_mode = optional(string, "CONFIG_MAP")<br>    compute_config = optional(object({<br>      node_pools = optional(list(string), ["general-purpose"])<br>    }))<br>    service_ipv4_cidr  = optional(string, "172.20.0.0/16")<br>    creation_role_name = optional(string, null)<br>    k8s_version        = optional(string, "1.27")<br>    nodes_master       = optional(bool, false)<br>    kubeconfig = optional(object({<br>      extra_args = optional(string, "")<br>      path       = optional(string, null)<br>    }), {})<br>    public_access = optional(object({<br>      enabled = optional(bool, false)<br>      cidrs   = optional(list(string), [])<br>    }), {})<br>    custom_role_maps = optional(list(object({<br>      rolearn  = string<br>      username = string<br>      groups   = list(string)<br>    })), [])<br>    master_role_names  = optional(list(string), [])<br>    cluster_addons     = optional(list(string), ["kube-proxy", "coredns", "vpc-cni"])<br>    ssm_log_group_name = optional(string, "session-manager")<br>    vpc_cni = optional(object({<br>      prefix_delegation = optional(bool, false)<br>      annotate_pod_ip   = optional(bool, true)<br>    }))<br>    identity_providers = optional(list(object({<br>      client_id                     = string<br>      groups_claim                  = optional(string, null)<br>      groups_prefix                 = optional(string, null)<br>      identity_provider_config_name = string<br>      issuer_url                    = optional(string, null)<br>      required_claims               = optional(map(string), null)<br>      username_claim                = optional(string, null)<br>      username_prefix               = optional(string, null)<br>    })), []),<br>  })</pre> | `{}` | no |
| <a name="input_ignore_tags"></a> [ignore\_tags](#input\_ignore\_tags) | Tag keys to be ignored by the aws provider. | `list(string)` | `[]` | no |
| <a name="input_kms_info"></a> [kms\_info](#input\_kms\_info) | key\_id  = KMS key id.<br>    key\_arn = KMS key arn.<br>    enabled = KMS key is enabled | <pre>object({<br>    key_id  = string<br>    key_arn = string<br>    enabled = bool<br>  })</pre> | n/a | yes |
| <a name="input_network_info"></a> [network\_info](#input\_network\_info) | id = VPC ID.<br>    ecr\_endpoint = {<br>      security\_group\_id = ECR Endpoint security group id.<br>    }<br>    subnets = {<br>      public = List of public Subnets.<br>      [{<br>        name = Subnet name.<br>        subnet\_id = Subnet ud<br>        az = Subnet availability\_zone<br>        az\_id = Subnet availability\_zone\_id<br>      }]<br>      private = List of private Subnets.<br>      [{<br>        name = Subnet name.<br>        subnet\_id = Subnet ud<br>        az = Subnet availability\_zone<br>        az\_id = Subnet availability\_zone\_id<br>      }]<br>      pod = List of pod Subnets.<br>      [{<br>        name = Subnet name.<br>        subnet\_id = Subnet ud<br>        az = Subnet availability\_zone<br>        az\_id = Subnet availability\_zone\_id<br>      }]<br>    } | <pre>object({<br>    vpc_id = string<br>    ecr_endpoint = optional(object({<br>      security_group_id = optional(string, null)<br>    }), null)<br>    subnets = object({<br>      public = list(object({<br>        name      = string<br>        subnet_id = string<br>        az        = string<br>        az_id     = string<br>      }))<br>      private = list(object({<br>        name      = string<br>        subnet_id = string<br>        az        = string<br>        az_id     = string<br>      }))<br>      pod = list(object({<br>        name      = string<br>        subnet_id = string<br>        az        = string<br>        az_id     = string<br>      }))<br>    })<br>    vpc_cidrs = optional(string, "10.0.0.0/16")<br>  })</pre> | n/a | yes |
| <a name="input_node_iam_policies"></a> [node\_iam\_policies](#input\_node\_iam\_policies) | Additional IAM Policy Arns for Nodes | `list(string)` | n/a | yes |
| <a name="input_privatelink"></a> [privatelink](#input\_privatelink) | {<br>      enabled = Enable Private Link connections.<br>      namespace = Namespace for IAM Policy conditions.<br>      monitoring\_bucket = Bucket for NLBs monitoring.<br>      route53\_hosted\_zone\_name = Hosted zone for External DNS zone.<br>      vpc\_endpoint\_services = [{<br>        name      = Name of the VPC Endpoint Service.<br>        ports     = List of ports exposing the VPC Endpoint Service. i.e [8080, 8081]<br>        cert\_arn  = Certificate ARN used by the NLB associated for the given VPC Endpoint Service.<br>        private\_dns = Private DNS for the VPC Endpoint Service.<br>      }]<br>    } | <pre>object({<br>    enabled                  = optional(bool, false)<br>    namespace                = optional(string, "domino-platform")<br>    monitoring_bucket        = optional(string, null)<br>    route53_hosted_zone_name = optional(string, null)<br>    vpc_endpoint_services = optional(list(object({<br>      name        = optional(string)<br>      ports       = optional(list(number))<br>      cert_arn    = optional(string)<br>      private_dns = optional(string)<br>    })), [])<br>  })</pre> | `{}` | no |
| <a name="input_region"></a> [region](#input\_region) | AWS region for the deployment | `string` | n/a | yes |
| <a name="input_ssh_key"></a> [ssh\_key](#input\_ssh\_key) | path          = SSH private key filepath.<br>    key\_pair\_name = AWS key\_pair name. | <pre>object({<br>    path          = string<br>    key_pair_name = string<br>  })</pre> | n/a | yes |
| <a name="input_storage_info"></a> [storage\_info](#input\_storage\_info) | Defines the configuration for different storage types like EFS, S3, and ECR. | <pre>object({<br>    efs = optional(object({<br>      security_group_id = optional(string, null)<br>    }), null)<br>    netapp = optional(object({<br>      svm = object({<br>        name             = optional(string, null)<br>        management_ip    = optional(string, null)<br>        nfs_ip           = optional(string, null)<br>        creds_secret_arn = optional(string, null)<br>      })<br>      filesystem = object({<br>        id                = optional(string, null)<br>        security_group_id = optional(string, null)<br>      })<br>      volume = object({<br>        name = optional(string, null)<br>      })<br>    }), null)<br>  })</pre> | `{}` | no |
| <a name="input_tags"></a> [tags](#input\_tags) | Deployment tags. | `map(string)` | `{}` | no |
| <a name="input_use_fips_endpoint"></a> [use\_fips\_endpoint](#input\_use\_fips\_endpoint) | Use aws FIPS endpoints | `bool` | `false` | no |

## Outputs

| Name | Description |
|------|-------------|
| <a name="output_info"></a> [info](#output\_info) | EKS information |
<!-- END OF PRE-COMMIT-TERRAFORM DOCS HOOK -->
