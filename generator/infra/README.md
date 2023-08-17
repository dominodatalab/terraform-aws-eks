# infra

<!-- BEGINNING OF PRE-COMMIT-TERRAFORM DOCS HOOK -->
## Requirements

| Name | Version |
|------|---------|
| <a name="requirement_terraform"></a> [terraform](#requirement\_terraform) | >= 1.4.0 |
| <a name="requirement_aws"></a> [aws](#requirement\_aws) | ~> 5.0 |

## Providers

| Name | Version |
|------|---------|
| <a name="provider_aws"></a> [aws](#provider\_aws) | ~> 5.0 |

## Modules

| Name | Source | Version |
|------|--------|---------|
| <a name="module_infra"></a> [infra](#module\_infra) | ./../../modules/infra | n/a |

## Resources

| Name | Type |
|------|------|
| [aws_ami.eks_node](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/data-sources/ami) | data source |

## Inputs

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|:--------:|
| <a name="input_additional_node_groups"></a> [additional\_node\_groups](#input\_additional\_node\_groups) | Additional EKS managed node groups definition. | <pre>map(object({<br>    ami                   = optional(string)<br>    bootstrap_extra_args  = optional(string)<br>    instance_types        = list(string)<br>    spot                  = optional(bool)<br>    min_per_az            = number<br>    max_per_az            = number<br>    desired_per_az        = number<br>    availability_zone_ids = list(string)<br>    labels                = map(string)<br>    taints = optional(list(object({<br>      key    = string<br>      value  = optional(string)<br>      effect = string<br>    })))<br>    tags = optional(map(string))<br>    gpu  = optional(bool)<br>    volume = object({<br>      size = string<br>      type = string<br>    })<br>  }))</pre> | `{}` | no |
| <a name="input_bastion"></a> [bastion](#input\_bastion) | enabled                  = Create bastion host.<br>    ami                      = Ami id. Defaults to latest 'amazon\_linux\_2' ami.<br>    instance\_type            = Instance type.<br>    authorized\_ssh\_ip\_ranges = List of CIDR ranges permitted for the bastion ssh access.<br>    username                 = Bastion user.<br>    install\_binaries         = Toggle to install required Domino binaries in the bastion. | <pre>object({<br>    enabled                  = optional(bool)<br>    ami_id                   = optional(string)<br>    instance_type            = optional(string)<br>    authorized_ssh_ip_ranges = optional(list(string))<br>    username                 = optional(string)<br>    install_binaries         = optional(bool)<br>  })</pre> | n/a | yes |
| <a name="input_default_node_groups"></a> [default\_node\_groups](#input\_default\_node\_groups) | EKS managed node groups definition. | <pre>object(<br>    {<br>      compute = object(<br>        {<br>          ami                   = optional(string, null)<br>          bootstrap_extra_args  = optional(string, "")<br>          instance_types        = optional(list(string), ["m5.2xlarge"])<br>          spot                  = optional(bool, false)<br>          min_per_az            = optional(number, 0)<br>          max_per_az            = optional(number, 10)<br>          desired_per_az        = optional(number, 0)<br>          availability_zone_ids = list(string)<br>          labels = optional(map(string), {<br>            "dominodatalab.com/node-pool" = "default"<br>          })<br>          taints = optional(list(object({<br>            key    = string<br>            value  = optional(string)<br>            effect = string<br>          })), [])<br>          tags = optional(map(string), {})<br>          gpu  = optional(bool, null)<br>          volume = optional(object({<br>            size = optional(number, 1000)<br>            type = optional(string, "gp3")<br>            }), {<br>            size = 1000<br>            type = "gp3"<br>            }<br>          )<br>      }),<br>      platform = object(<br>        {<br>          ami                   = optional(string, null)<br>          bootstrap_extra_args  = optional(string, "")<br>          instance_types        = optional(list(string), ["m5.2xlarge"])<br>          spot                  = optional(bool, false)<br>          min_per_az            = optional(number, 1)<br>          max_per_az            = optional(number, 10)<br>          desired_per_az        = optional(number, 1)<br>          availability_zone_ids = list(string)<br>          labels = optional(map(string), {<br>            "dominodatalab.com/node-pool" = "platform"<br>          })<br>          taints = optional(list(object({<br>            key    = string<br>            value  = optional(string)<br>            effect = string<br>          })), [])<br>          tags = optional(map(string), {})<br>          gpu  = optional(bool, null)<br>          volume = optional(object({<br>            size = optional(number, 100)<br>            type = optional(string, "gp3")<br>            }), {<br>            size = 100<br>            type = "gp3"<br>            }<br>          )<br>      }),<br>      gpu = object(<br>        {<br>          ami                   = optional(string, null)<br>          bootstrap_extra_args  = optional(string, "")<br>          instance_types        = optional(list(string), ["g4dn.xlarge"])<br>          spot                  = optional(bool, false)<br>          min_per_az            = optional(number, 0)<br>          max_per_az            = optional(number, 10)<br>          desired_per_az        = optional(number, 0)<br>          availability_zone_ids = list(string)<br>          labels = optional(map(string), {<br>            "dominodatalab.com/node-pool" = "default-gpu"<br>            "nvidia.com/gpu"              = true<br>          })<br>          taints = optional(list(object({<br>            key    = string<br>            value  = optional(string)<br>            effect = string<br>            })), [{<br>            key    = "nvidia.com/gpu"<br>            value  = "true"<br>            effect = "NO_SCHEDULE"<br>            }<br>          ])<br>          tags = optional(map(string))<br>          gpu  = optional(bool)<br>          volume = optional(object({<br>            size = optional(number)<br>            type = optional(string)<br>          }))<br>      })<br>  })</pre> | n/a | yes |
| <a name="input_deploy_id"></a> [deploy\_id](#input\_deploy\_id) | Domino Deployment ID. | `string` | n/a | yes |
| <a name="input_eks"></a> [eks](#input\_eks) | k8s\_version = EKS cluster k8s version.<br>    kubeconfig = {<br>      extra\_args = Optional extra args when generating kubeconfig.<br>      path       = Fully qualified path name to write the kubeconfig file.<br>    }<br>    public\_access = {<br>      enabled = Enable EKS API public endpoint.<br>      cidrs   = List of CIDR ranges permitted for accessing the EKS public endpoint.<br>    }<br>    "Custom role maps for aws auth configmap<br>    custom\_role\_maps = {<br>      rolearn  = string<br>      username = string<br>      groups   = list(string)<br>    }<br>    master\_role\_names  = IAM role names to be added as masters in eks.<br>    cluster\_addons     = EKS cluster addons. vpc-cni is installed separately.<br>    vpc\_cni            = Configuration for AWS VPC CNI<br>    ssm\_log\_group\_name = CloudWatch log group to send the SSM session logs to.<br>    identity\_providers = Configuration for IDP(Identity Provider).<br>  } | <pre>object({<br>    k8s_version = optional(string)<br>    kubeconfig = optional(object({<br>      extra_args = optional(string)<br>      path       = optional(string)<br>    }), {})<br>    public_access = optional(object({<br>      enabled = optional(bool)<br>      cidrs   = optional(list(string))<br>    }), {})<br>    custom_role_maps = optional(list(object({<br>      rolearn  = string<br>      username = string<br>      groups   = list(string)<br>    })))<br>    master_role_names  = optional(list(string))<br>    cluster_addons     = optional(list(string))<br>    ssm_log_group_name = optional(string)<br>    vpc_cni = optional(object({<br>      prefix_delegation = optional(bool)<br>    }))<br>    identity_providers = optional(list(object({<br>      client_id                     = string<br>      groups_claim                  = optional(string)<br>      groups_prefix                 = optional(string)<br>      identity_provider_config_name = string<br>      issuer_url                    = optional(string)<br>      required_claims               = optional(string)<br>      username_claim                = optional(string)<br>      username_prefix               = optional(string)<br>    })))<br>  })</pre> | `{}` | no |
| <a name="input_kms"></a> [kms](#input\_kms) | enabled = Toggle,if set use either the specified KMS key\_id or a Domino-generated one.<br>    key\_id  = optional(string, null) | <pre>object({<br>    enabled = optional(bool)<br>    key_id  = optional(string)<br>  })</pre> | n/a | yes |
| <a name="input_region"></a> [region](#input\_region) | AWS region for the deployment | `string` | n/a | yes |
| <a name="input_route53_hosted_zone_name"></a> [route53\_hosted\_zone\_name](#input\_route53\_hosted\_zone\_name) | Optional hosted zone for External DNS zone. | `string` | n/a | yes |
| <a name="input_ssh_pvt_key_path"></a> [ssh\_pvt\_key\_path](#input\_ssh\_pvt\_key\_path) | SSH private key filepath. | `string` | n/a | yes |
| <a name="input_tags"></a> [tags](#input\_tags) | Deployment tags. | `map(string)` | n/a | yes |

## Outputs

| Name | Description |
|------|-------------|
| <a name="output_infra"></a> [infra](#output\_infra) | Infrastructure outputs. |
<!-- END OF PRE-COMMIT-TERRAFORM DOCS HOOK -->
