# vpn

<!-- BEGIN_TF_DOCS -->
## Requirements

| Name | Version |
|------|---------|
| <a name="requirement_terraform"></a> [terraform](#requirement\_terraform) | >= 1.0 |
| <a name="requirement_aws"></a> [aws](#requirement\_aws) | ~> 6.0 |

## Providers

| Name | Version |
|------|---------|
| <a name="provider_aws"></a> [aws](#provider\_aws) | ~> 6.0 |

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
| <a name="input_deploy_id"></a> [deploy\_id](#input\_deploy\_id) | Domino Deployment ID | `string` | n/a | yes |
| <a name="input_network_info"></a> [network\_info](#input\_network\_info) | id = VPC ID.<br/>    subnets = {<br/>      public = List of public Subnets.<br/>      [{<br/>        name = Subnet name.<br/>        subnet\_id = Subnet ud<br/>        az = Subnet availability\_zone<br/>        az\_id = Subnet availability\_zone\_id<br/>      }]<br/>      private = List of private Subnets.<br/>      [{<br/>        name = Subnet name.<br/>        subnet\_id = Subnet ud<br/>        az = Subnet availability\_zone<br/>        az\_id = Subnet availability\_zone\_id<br/>      }]<br/>      pod = List of pod Subnets.<br/>      [{<br/>        name = Subnet name.<br/>        subnet\_id = Subnet ud<br/>        az = Subnet availability\_zone<br/>        az\_id = Subnet availability\_zone\_id<br/>      }]<br/>    } | <pre>object({<br/>    vpc_id = string<br/>    route_tables = object({<br/>      public  = optional(list(string))<br/>      private = optional(list(string))<br/>      pod     = optional(list(string))<br/>    })<br/>    subnets = object({<br/>      public = list(object({<br/>        name      = string<br/>        subnet_id = string<br/>        az        = string<br/>        az_id     = string<br/>      }))<br/>      private = list(object({<br/>        name      = string<br/>        subnet_id = string<br/>        az        = string<br/>        az_id     = string<br/>      }))<br/>      pod = list(object({<br/>        name      = string<br/>        subnet_id = string<br/>        az        = string<br/>        az_id     = string<br/>      }))<br/>    })<br/>    vpc_cidrs = string<br/>  })</pre> | n/a | yes |
| <a name="input_vpn_connections"></a> [vpn\_connections](#input\_vpn\_connections) | List of VPN connections, each with:<br/>    - name: Name for identification<br/>    - shared\_ip: Customer's shared IP Address.<br/>    - cidr\_block: List of CIDR blocks for the customer's network. | <pre>list(object({<br/>    name        = string<br/>    shared_ip   = string<br/>    cidr_blocks = list(string)<br/>  }))</pre> | n/a | yes |

## Outputs

| Name | Description |
|------|-------------|
| <a name="output_vpn_connections"></a> [vpn\_connections](#output\_vpn\_connections) | List of VPN connections information |
<!-- END_TF_DOCS -->
