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
| [aws_iam_policy.load_balancer_controller](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/iam_policy) | resource |
| [aws_iam_role.load_balancer_controller](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/iam_role) | resource |
| [aws_iam_role_policy_attachment.load_balancer_controller](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/iam_role_policy_attachment) | resource |
| [aws_lb.nlbs](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/lb) | resource |
| [aws_lb_listener.listeners](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/lb_listener) | resource |
| [aws_lb_target_group.target_groups](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/lb_target_group) | resource |
| [aws_route53_record.service_endpoint_private_dns_verification](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/route53_record) | resource |
| [aws_vpc_endpoint_service.vpc_endpoint_services](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/vpc_endpoint_service) | resource |
| [random_string.target_group_random_gen](https://registry.terraform.io/providers/hashicorp/random/latest/docs/resources/string) | resource |
| [aws_iam_policy_document.load_balancer_controller](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/data-sources/iam_policy_document) | data source |
| [aws_iam_policy_document.load_balancer_controller_policy](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/data-sources/iam_policy_document) | data source |
| [aws_partition.current](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/data-sources/partition) | data source |
| [aws_route53_zone.hosted](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/data-sources/route53_zone) | data source |

## Inputs

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|:--------:|
| <a name="input_deploy_id"></a> [deploy\_id](#input\_deploy\_id) | Domino Deployment ID | `string` | n/a | yes |
| <a name="input_network_info"></a> [network\_info](#input\_network\_info) | {<br>      vpc\_id = VPC Id.<br>      subnets = {<br>        private = Private subnets.<br>        public  = Public subnets.<br>        pod     = Pod subnets.<br>      }), {})<br>    }), {}) | <pre>object({<br>    vpc_id = string<br>    subnets = object({<br>      private = list(object({<br>        name      = string<br>        subnet_id = string<br>        az        = string<br>        az_id     = string<br>      }))<br>      public = list(object({<br>        name      = string<br>        subnet_id = string<br>        az        = string<br>        az_id     = string<br>      }))<br>      pod = list(object({<br>        name      = string<br>        subnet_id = string<br>        az        = string<br>        az_id     = string<br>      }))<br>    })<br>  })</pre> | n/a | yes |
| <a name="input_oidc_provider_id"></a> [oidc\_provider\_id](#input\_oidc\_provider\_id) | OIDC Provider ID | `string` | n/a | yes |
| <a name="input_privatelink"></a> [privatelink](#input\_privatelink) | {<br>      enabled = Enable Private Link connections.<br>      namespace = Namespace for IAM Policy conditions.<br>      monitoring\_bucket = Bucket for NLBs monitoring.<br>      route53\_hosted\_zone\_name = Hosted zone for External DNS zone.<br>      vpc\_endpoint\_services = [{<br>        name      = Name of the VPC Endpoint Service.<br>        ports     = List of ports exposing the VPC Endpoint Service. i.e [8080, 8081]<br>        cert\_arn  = Certificate ARN used by the NLB associated for the given VPC Endpoint Service.<br>        private\_dns = Private DNS for the VPC Endpoint Service.<br>      }]<br>    } | <pre>object({<br>    enabled                  = optional(bool, false)<br>    namespace                = optional(string, "domino-platform")<br>    monitoring_bucket        = optional(string, null)<br>    route53_hosted_zone_name = optional(string, null)<br>    vpc_endpoint_services = optional(list(object({<br>      name        = optional(string)<br>      ports       = optional(list(number))<br>      cert_arn    = optional(string)<br>      private_dns = optional(string)<br>    })), [])<br>  })</pre> | `{}` | no |

## Outputs

| Name | Description |
|------|-------------|
| <a name="output_info"></a> [info](#output\_info) | Target groups... |
+<!-- END OF PRE-COMMIT-TERRAFORM DOCS HOOK -->
