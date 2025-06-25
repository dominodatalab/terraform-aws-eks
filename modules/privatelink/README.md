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
| [aws_route53_record.service_endpoint_private_dns_verification](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/route53_record) | resource |
| [aws_vpc_endpoint_service.vpc_endpoint_services](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/vpc_endpoint_service) | resource |
| [aws_route53_zone.hosted](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/data-sources/route53_zone) | data source |

## Inputs

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|:--------:|
| <a name="input_deploy_id"></a> [deploy\_id](#input\_deploy\_id) | Domino Deployment ID | `string` | n/a | yes |
| <a name="input_lb_arns"></a> [lb\_arns](#input\_lb\_arns) | Map of Load Balancer ARNs used by the VPC Endpoint Services.<br/><br/>    Expected format:<br/>      {<br/>        service-name-1 = "<ARN\_HERE>"<br/>        service-name-2 = "<ARN\_HERE>"<br/>      }<br/>    Keys must match `name` fields in `privatelink.vpc_endpoint_services`. | `map(string)` | `{}` | no |
| <a name="input_privatelink"></a> [privatelink](#input\_privatelink) | {<br/>      enabled = Enable Private Link connections.<br/>      route53\_hosted\_zone\_name = Hosted zone for External DNS zone.<br/>      vpc\_endpoint\_services = [{<br/>        name      = Name of the VPC Endpoint Service.<br/>        ports     = List of ports exposing the VPC Endpoint Service. i.e [8080, 8081]<br/>        cert\_arn  = Certificate ARN used by the NLB associated for the given VPC Endpoint Service.<br/>        private\_dns = Private DNS for the VPC Endpoint Service.<br/>        supported\_regions = The set of regions from which service consumers can access the service.<br/>      }]<br/>    } | <pre>object({<br/>    enabled                  = optional(bool, false)<br/>    route53_hosted_zone_name = optional(string, null)<br/>    vpc_endpoint_services = optional(list(object({<br/>      name              = optional(string)<br/>      private_dns       = optional(string)<br/>      supported_regions = optional(set(string))<br/>    })), [])<br/>  })</pre> | `{}` | no |

## Outputs

No outputs.
<!-- END_TF_DOCS -->
