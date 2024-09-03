# vpn

<!-- BEGINNING OF PRE-COMMIT-TERRAFORM DOCS HOOK -->
## Requirements

| Name | Version |
|------|---------|
| <a name="requirement_terraform"></a> [terraform](#requirement\_terraform) | >= 1.0 |
| <a name="requirement_aws"></a> [aws](#requirement\_aws) | ~> 5.0 |

## Providers

| Name | Version |
|------|---------|
| <a name="provider_aws"></a> [aws](#provider\_aws) | ~> 5.0 |

## Modules

No modules.

## Resources

| Name | Type |
|------|------|
| [aws_customer_gateway.customer_gateway](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/customer_gateway) | resource |
| [aws_vpn_connection.this](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/vpn_connection) | resource |
| [aws_vpn_connection_route.this](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/vpn_connection_route) | resource |
| [aws_vpn_gateway.this](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/vpn_gateway) | resource |
| [aws_vpn_gateway_attachment.this](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/vpn_gateway_attachment) | resource |
| [aws_vpn_gateway_route_propagation.route_propagation](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/vpn_gateway_route_propagation) | resource |

## Inputs

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|:--------:|
| <a name="input_customer_info"></a> [customer\_info](#input\_customer\_info) | Information regarding the remote VPN connection, including the shared IP address and the CIDR block for the customer's network. | <pre>object({<br>    shared_ip  = string<br>    cidr_block = string<br>  })</pre> | n/a | yes |
| <a name="input_deploy_id"></a> [deploy\_id](#input\_deploy\_id) | Domino Deployment ID | `string` | n/a | yes |
| <a name="input_ignore_tags"></a> [ignore\_tags](#input\_ignore\_tags) | Tag keys to be ignored by the aws provider. | `list(string)` | `[]` | no |
| <a name="input_network_info"></a> [network\_info](#input\_network\_info) | id = VPC ID.<br>    subnets = {<br>      public = List of public Subnets.<br>      [{<br>        name = Subnet name.<br>        subnet\_id = Subnet ud<br>        az = Subnet availability\_zone<br>        az\_id = Subnet availability\_zone\_id<br>      }]<br>      private = List of private Subnets.<br>      [{<br>        name = Subnet name.<br>        subnet\_id = Subnet ud<br>        az = Subnet availability\_zone<br>        az\_id = Subnet availability\_zone\_id<br>      }]<br>      pod = List of pod Subnets.<br>      [{<br>        name = Subnet name.<br>        subnet\_id = Subnet ud<br>        az = Subnet availability\_zone<br>        az\_id = Subnet availability\_zone\_id<br>      }]<br>    } | <pre>object({<br>    vpc_id = string<br>    subnets = object({<br>      public = list(object({<br>        name      = string<br>        subnet_id = string<br>        az        = string<br>        az_id     = string<br>      }))<br>      private = list(object({<br>        name      = string<br>        subnet_id = string<br>        az        = string<br>        az_id     = string<br>      }))<br>      pod = list(object({<br>        name      = string<br>        subnet_id = string<br>        az        = string<br>        az_id     = string<br>      }))<br>    })<br>    vpc_cidrs = string<br>  })</pre> | n/a | yes |
| <a name="input_region"></a> [region](#input\_region) | AWS region for the deployment | `string` | n/a | yes |
| <a name="input_use_fips_endpoint"></a> [use\_fips\_endpoint](#input\_use\_fips\_endpoint) | Use aws FIPS endpoints | `bool` | `false` | no |

## Outputs

| Name | Description |
|------|-------------|
| <a name="output_vpn"></a> [vpn](#output\_vpn) | VPN connection information |
<!-- END OF PRE-COMMIT-TERRAFORM DOCS HOOK -->
