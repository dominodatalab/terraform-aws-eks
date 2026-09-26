# load_balancers

Provisions the ALB/NLB load balancers, Global Accelerator, WAF and (optionally) PrivateLink
endpoint services fronting the Domino instance.

This stack only depends on `cluster` (for the EKS node security group) and `infra` (for
network/monitoring bucket info) - it does **not** depend on, and is not depended on by,
`nodes`. Run it in parallel with `nodes` (`./tf.sh all apply` does this) instead of
sequentially, so Global Accelerator's slow endpoint-group propagation (commonly 8+ minutes)
overlaps with node-group/add-on provisioning instead of adding to the total deploy time.

Leave `load_balancers` at its default `[]` to skip this stack entirely.

<!-- BEGIN_TF_DOCS -->
## Requirements

| Name | Version |
| ---- | ------- |
| <a name="requirement_terraform"></a> [terraform](#requirement\_terraform) | >= 1.4.0 |
| <a name="requirement_aws"></a> [aws](#requirement\_aws) | ~> 6.0 |

## Providers

| Name | Version |
| ---- | ------- |
| <a name="provider_terraform"></a> [terraform](#provider\_terraform) | n/a |

## Modules

| Name | Source | Version |
| ---- | ------ | ------- |
| <a name="module_load_balancers"></a> [load\_balancers](#module\_load\_balancers) | ./../../../../modules/load-balancers | n/a |
| <a name="module_privatelink"></a> [privatelink](#module\_privatelink) | ./../../../../modules/privatelink | n/a |

## Resources

| Name | Type |
| ---- | ---- |
| [terraform_remote_state.eks](https://registry.terraform.io/providers/hashicorp/terraform/latest/docs/data-sources/remote_state) | data source |
| [terraform_remote_state.infra](https://registry.terraform.io/providers/hashicorp/terraform/latest/docs/data-sources/remote_state) | data source |

## Inputs

| Name | Description | Type | Default | Required |
| ---- | ----------- | ---- | ------- | :------: |
| <a name="input_access_logs"></a> [access\_logs](#input\_access\_logs) | Enable ALB/NLB access logs. Stored in the infra monitoring bucket. | <pre>object({<br/>    enabled = optional(bool, false)<br/>  })</pre> | `{}` | no |
| <a name="input_connection_logs"></a> [connection\_logs](#input\_connection\_logs) | Enable NLB connection logs. Stored in the infra monitoring bucket. | <pre>object({<br/>    enabled = optional(bool, false)<br/>  })</pre> | `{}` | no |
| <a name="input_flow_logs"></a> [flow\_logs](#input\_flow\_logs) | Enable Global Accelerator flow logs. Stored in the infra monitoring bucket. | <pre>object({<br/>    enabled = optional(bool, false)<br/>  })</pre> | `{}` | no |
| <a name="input_hosted_zone_private"></a> [hosted\_zone\_private](#input\_hosted\_zone\_private) | Whether the Route53 hosted zone is private. | `bool` | `false` | no |
| <a name="input_load_balancers"></a> [load\_balancers](#input\_load\_balancers) | List of Load Balancers to create. See modules/load-balancers variables.tf for the full shape. | <pre>list(object({<br/>    name            = string<br/>    type            = string<br/>    internal        = optional(bool, true)<br/>    ddos_protection = optional(bool, true)<br/>    idle_timeout    = optional(number, 3600)<br/>    listeners = list(object({<br/>      name                = string<br/>      port                = number<br/>      protocol            = string<br/>      tg_protocol         = string<br/>      tg_protocol_version = optional(string)<br/>      ssl_policy          = optional(string)<br/>      cert_arn            = optional(string)<br/>    }))<br/>  }))</pre> | `[]` | no |
| <a name="input_privatelink"></a> [privatelink](#input\_privatelink) | PrivateLink configuration fronting the load balancers created by this stack. See modules/privatelink variables.tf for the full shape. | <pre>object({<br/>    enabled                  = optional(bool, false)<br/>    route53_hosted_zone_name = optional(string, null)<br/>    vpc_endpoint_services = optional(list(object({<br/>      name              = optional(string)<br/>      lb_name           = optional(string)<br/>      private_dns       = optional(string)<br/>      supported_regions = optional(set(string))<br/>    })), [])<br/>  })</pre> | `{}` | no |
| <a name="input_route53_hosted_zone_name"></a> [route53\_hosted\_zone\_name](#input\_route53\_hosted\_zone\_name) | Route53 hosted zone name to create the Domino instance's DNS records in. | `string` | `null` | no |
| <a name="input_use_fips_endpoint"></a> [use\_fips\_endpoint](#input\_use\_fips\_endpoint) | Use aws FIPS endpoints | `bool` | `false` | no |
| <a name="input_waf"></a> [waf](#input\_waf) | Web Application Firewall (WAF) configuration applied to the load balancers. See modules/load-balancers variables.tf for the full shape. | <pre>object({<br/>    enabled         = bool<br/>    override_action = optional(string, "none")<br/>    rules = optional(list(object({<br/>      name        = string<br/>      vendor_name = string<br/>      priority    = number<br/>      allow       = optional(list(string), [])<br/>      block       = optional(list(string), [])<br/>      captcha     = optional(list(string), [])<br/>      challenge   = optional(list(string), [])<br/>      count       = optional(list(string), [])<br/>    })), [])<br/>    rate_limit = object({<br/>      enabled = bool<br/>      limit   = number<br/>      action  = string<br/>    })<br/>    block_forwarder_header = object({<br/>      enabled = bool<br/>    })<br/>  })</pre> | <pre>{<br/>  "block_forwarder_header": {<br/>    "enabled": false<br/>  },<br/>  "enabled": false,<br/>  "rate_limit": {<br/>    "action": "count",<br/>    "enabled": false,<br/>    "limit": 1000<br/>  }<br/>}</pre> | no |

## Outputs

| Name | Description |
| ---- | ----------- |
| <a name="output_load_balancers"></a> [load\_balancers](#output\_load\_balancers) | Load balancer details (ARNs, target groups). |
| <a name="output_privatelink"></a> [privatelink](#output\_privatelink) | PrivateLink details. |
<!-- END_TF_DOCS -->
