# nat-instance

<!-- BEGINNING OF PRE-COMMIT-TERRAFORM DOCS HOOK -->
## Requirements

| Name | Version |
|------|---------|
| <a name="requirement_terraform"></a> [terraform](#requirement\_terraform) | >= 1.0 |
| <a name="requirement_aws"></a> [aws](#requirement\_aws) | ~> 5.0 |
| <a name="requirement_null"></a> [null](#requirement\_null) | >= 3.1.0 |

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
| [aws_route_table.nat_instance](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/route_table) | resource |
| [aws_route_table_association.nat](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/route_table_association) | resource |
| [aws_security_group_rule.bastion_nat](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/security_group_rule) | resource |
| [terraform_data.nat_instance](https://registry.terraform.io/providers/hashicorp/terraform/latest/docs/resources/data) | resource |
| [aws_network_interface.bastion](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/data-sources/network_interface) | data source |
| [aws_subnet.subnets](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/data-sources/subnet) | data source |

## Inputs

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|:--------:|
| <a name="input_bastion_info"></a> [bastion\_info](#input\_bastion\_info) | user                = Bastion username.<br>    public\_ip           = Bastion public ip.<br>    security\_group\_id   = Bastion sg id.<br>    ssh\_bastion\_command = Command to ssh onto bastion. | <pre>object({<br>    user                = string<br>    public_ip           = string<br>    security_group_id   = string<br>    ssh_bastion_command = string<br>  })</pre> | n/a | yes |
| <a name="input_deploy_id"></a> [deploy\_id](#input\_deploy\_id) | Domino Deployment ID | `string` | n/a | yes |
| <a name="input_network_info"></a> [network\_info](#input\_network\_info) | id = VPC ID.<br>    subnets = {<br>      public = List of public Subnets.<br>      [{<br>        name = Subnet name.<br>        subnet\_id = Subnet ud<br>        az = Subnet availability\_zone<br>        az\_id = Subnet availability\_zone\_id<br>      }]<br>      private = List of private Subnets.<br>      [{<br>        name = Subnet name.<br>        subnet\_id = Subnet ud<br>        az = Subnet availability\_zone<br>        az\_id = Subnet availability\_zone\_id<br>      }]<br>      pod = List of pod Subnets.<br>      [{<br>        name = Subnet name.<br>        subnet\_id = Subnet ud<br>        az = Subnet availability\_zone<br>        az\_id = Subnet availability\_zone\_id<br>      }]<br>    } | <pre>object({<br>    vpc_id = string<br>    subnets = object({<br>      public = list(object({<br>        name      = string<br>        subnet_id = string<br>        az        = string<br>        az_id     = string<br>      }))<br>      private = optional(list(object({<br>        name      = string<br>        subnet_id = string<br>        az        = string<br>        az_id     = string<br>      })), [])<br>      pod = optional(list(object({<br>        name      = string<br>        subnet_id = string<br>        az        = string<br>        az_id     = string<br>      })), [])<br>    })<br>  })</pre> | n/a | yes |
| <a name="input_ssh_key"></a> [ssh\_key](#input\_ssh\_key) | path          = SSH private key filepath.<br>    key\_pair\_name = AWS key\_pair name. | <pre>object({<br>    path          = string<br>    key_pair_name = string<br>  })</pre> | n/a | yes |

## Outputs

No outputs.
<!-- END OF PRE-COMMIT-TERRAFORM DOCS HOOK -->
