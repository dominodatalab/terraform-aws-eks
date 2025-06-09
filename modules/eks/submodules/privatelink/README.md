<!-- BEGIN_TF_DOCS -->
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
| [aws_lb.nlbs](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/lb) | resource |
| [aws_lb_listener.listeners](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/lb_listener) | resource |
| [aws_lb_target_group.target_groups](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/lb_target_group) | resource |
| [aws_route53_record.service_endpoint_private_dns_verification](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/route53_record) | resource |
| [aws_security_group.nlb_sg](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/security_group) | resource |
| [aws_vpc_endpoint_service.vpc_endpoint_services](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/vpc_endpoint_service) | resource |
| [aws_partition.current](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/data-sources/partition) | data source |
| [aws_route53_zone.hosted](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/data-sources/route53_zone) | data source |

## Inputs

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|:--------:|
| <a name="input_deploy_id"></a> [deploy\_id](#input\_deploy\_id) | Domino Deployment ID | `string` | n/a | yes |
| <a name="input_network_info"></a> [network\_info](#input\_network\_info) | {<br/>      vpc\_id = VPC Id.<br/>      subnets = {<br/>        private = Private subnets.<br/>        public  = Public subnets.<br/>        pod     = Pod subnets.<br/>      }), {})<br/>    }), {}) | <pre>object({<br/>    vpc_id = string<br/>    subnets = object({<br/>      private = list(object({<br/>        name      = string<br/>        subnet_id = string<br/>        az        = string<br/>        az_id     = string<br/>      }))<br/>      public = list(object({<br/>        name      = string<br/>        subnet_id = string<br/>        az        = string<br/>        az_id     = string<br/>      }))<br/>      pod = list(object({<br/>        name      = string<br/>        subnet_id = string<br/>        az        = string<br/>        az_id     = string<br/>      }))<br/>    })<br/>    vpc_cidrs = string<br/>  })</pre> | n/a | yes |
| <a name="input_privatelink"></a> [privatelink](#input\_privatelink) | {<br/>      enabled = Enable Private Link connections.<br/>      monitoring\_bucket = Bucket for NLBs monitoring.<br/>      route53\_hosted\_zone\_name = Hosted zone for External DNS zone.<br/>      vpc\_endpoint\_services = [{<br/>        name      = Name of the VPC Endpoint Service.<br/>        ports     = List of ports exposing the VPC Endpoint Service. i.e [8080, 8081]<br/>        cert\_arn  = Certificate ARN used by the NLB associated for the given VPC Endpoint Service.<br/>        private\_dns = Private DNS for the VPC Endpoint Service.<br/>        supported\_regions = The set of regions from which service consumers can access the service.<br/>      }]<br/>    } | <pre>object({<br/>    enabled                  = optional(bool, false)<br/>    monitoring_bucket        = optional(string, null)<br/>    route53_hosted_zone_name = optional(string, null)<br/>    vpc_endpoint_services = optional(list(object({<br/>      name              = optional(string)<br/>      ports             = optional(list(number))<br/>      cert_arn          = optional(string)<br/>      private_dns       = optional(string)<br/>      supported_regions = optional(set(string))<br/>    })), [])<br/>  })</pre> | `{}` | no |

## Outputs

| Name | Description |
|------|-------------|
| <a name="output_info"></a> [info](#output\_info) | Target groups... |
<!-- END_TF_DOCS -->
