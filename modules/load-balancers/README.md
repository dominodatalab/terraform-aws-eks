Load Balancers
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
| [aws_cloudwatch_log_group.waf_logs](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/cloudwatch_log_group) | resource |
| [aws_globalaccelerator_accelerator.main_accelerator](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/globalaccelerator_accelerator) | resource |
| [aws_globalaccelerator_endpoint_group.endpoint_group](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/globalaccelerator_endpoint_group) | resource |
| [aws_globalaccelerator_listener.listener](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/globalaccelerator_listener) | resource |
| [aws_lb.load_balancers](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/lb) | resource |
| [aws_lb_listener.load_balancer_listener](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/lb_listener) | resource |
| [aws_lb_target_group.lb_target_groups](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/lb_target_group) | resource |
| [aws_route53_record.lbs_dns_records](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/route53_record) | resource |
| [aws_route53_record.public_lbs_record_type_a](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/route53_record) | resource |
| [aws_route53_record.public_lbs_record_type_aaaa](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/route53_record) | resource |
| [aws_s3_bucket.waf_logs](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/s3_bucket) | resource |
| [aws_s3_bucket_public_access_block.waf_logs](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/s3_bucket_public_access_block) | resource |
| [aws_security_group.lb_security_groups](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/security_group) | resource |
| [aws_security_group_rule.allow_all_egress](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/security_group_rule) | resource |
| [aws_security_group_rule.allow_all_from_ddos_lb](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/security_group_rule) | resource |
| [aws_security_group_rule.lb_ingress_from_global_accelerator](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/security_group_rule) | resource |
| [aws_security_group_rule.lb_ingress_from_public_listeners_without_ddos_protection](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/security_group_rule) | resource |
| [aws_wafv2_web_acl.waf](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/wafv2_web_acl) | resource |
| [aws_wafv2_web_acl_association.alb_association](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/wafv2_web_acl_association) | resource |
| [aws_wafv2_web_acl_logging_configuration.application](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/wafv2_web_acl_logging_configuration) | resource |
| [aws_route53_zone.hosted](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/data-sources/route53_zone) | data source |
| [aws_security_group.global_accelerator_sg](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/data-sources/security_group) | data source |

## Inputs

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|:--------:|
| <a name="input_access_logs"></a> [access\_logs](#input\_access\_logs) | access\_logs = {<br/>      enabled   = Enable access logs.<br/>      s3\_bucket = The name of the S3 bucket where access logs will be stored.<br/>      s3\_prefix = The prefix (folder path) within the S3 bucket for access logs.<br/>    } | <pre>object({<br/>    enabled   = optional(bool, false)<br/>    s3_bucket = optional(string, null)<br/>    s3_prefix = optional(string, "access_logs/load_balancers")<br/>  })</pre> | n/a | yes |
| <a name="input_apps_prefix"></a> [apps\_prefix](#input\_apps\_prefix) | Prefix for application DNS records (optional). Will be prepended directly before fqdn without a dot. | `string` | `null` | no |
| <a name="input_connection_logs"></a> [connection\_logs](#input\_connection\_logs) | connection\_logs = {<br/>      enabled   = Enable connections logs.<br/>      s3\_bucket = The name of the S3 bucket where connection logs will be stored.<br/>      s3\_prefix = The prefix (folder path) within the S3 bucket for conneciton logs.<br/>    } | <pre>object({<br/>    enabled   = optional(bool, false)<br/>    s3_bucket = optional(string, null)<br/>    s3_prefix = optional(string, "connection_logs/load_balancers")<br/>  })</pre> | n/a | yes |
| <a name="input_deploy_id"></a> [deploy\_id](#input\_deploy\_id) | Domino Deployment ID | `string` | n/a | yes |
| <a name="input_eks_nodes_security_group_id"></a> [eks\_nodes\_security\_group\_id](#input\_eks\_nodes\_security\_group\_id) | Security group used by EKS nodes | `string` | n/a | yes |
| <a name="input_flow_logs"></a> [flow\_logs](#input\_flow\_logs) | connection\_logs = {<br/>      enabled   = Enable flow logs.<br/>      s3\_bucket = The name of the S3 bucket where flow logs will be stored.<br/>      s3\_prefix = The prefix (folder path) within the S3 bucket for flow logs.<br/>    } | <pre>object({<br/>    enabled   = optional(bool, false)<br/>    s3_bucket = optional(string, null)<br/>    s3_prefix = optional(string, "flow_logs/global_accelerator")<br/>  })</pre> | n/a | yes |
| <a name="input_fqdn"></a> [fqdn](#input\_fqdn) | Fully qualified domain name (FQDN) of the Domino instance | `string` | n/a | yes |
| <a name="input_hosted_zone_name"></a> [hosted\_zone\_name](#input\_hosted\_zone\_name) | Full name of the hosted zone | `string` | n/a | yes |
| <a name="input_hosted_zone_private"></a> [hosted\_zone\_private](#input\_hosted\_zone\_private) | Use private hosted zone | `bool` | `false` | no |
| <a name="input_load_balancers"></a> [load\_balancers](#input\_load\_balancers) | List of Load Balancers to create.<br/>    [{<br/>      name     = Name of the Load Balancer.<br/>      type     = Type of Load Balancer (e.g., "application", "network").<br/>      internal = (Optional) Whether the Load Balancer is internal. Defaults to true.<br/>      ddos\_protection = (Optional) Whether to enable AWS Shield Standard (DDoS protection). Defaults to true.<br/>      listeners = List of listeners for the Load Balancer.<br/>      [{<br/>        name        = Listener name.<br/>        port        = Listener port (e.g., 80, 443).<br/>        protocol    = Protocol used by the listener (e.g., "HTTP", "HTTPS").<br/>        tg\_protocol = Protocol used by the target group (e.g., "HTTP", "HTTPS").<br/>        ssl\_policy  = (Optional) SSL policy to use for HTTPS listeners.<br/>        cert\_arn    = (Optional) ARN of the SSL certificate.<br/>      }]<br/>    }] | <pre>list(object({<br/>    name            = string<br/>    type            = string<br/>    internal        = optional(bool, true)<br/>    ddos_protection = optional(bool, true)<br/>    listeners = list(object({<br/>      name                = string<br/>      port                = number<br/>      protocol            = string<br/>      tg_protocol         = string<br/>      tg_protocol_version = optional(string)<br/>      ssl_policy          = optional(string)<br/>      cert_arn            = optional(string)<br/>    }))<br/>  }))</pre> | n/a | yes |
| <a name="input_network_info"></a> [network\_info](#input\_network\_info) | vpc\_id = VPC ID.<br/>    subnets = {<br/>      public = List of public Subnets.<br/>      [{<br/>        name = Subnet name.<br/>        subnet\_id = Subnet ud<br/>        az = Subnet availability\_zone<br/>        az\_id = Subnet availability\_zone\_id<br/>      }]<br/>      private = List of private Subnets.<br/>      [{<br/>        name = Subnet name.<br/>        subnet\_id = Subnet ud<br/>        az = Subnet availability\_zone<br/>        az\_id = Subnet availability\_zone\_id<br/>      }]<br/>    } | <pre>object({<br/>    vpc_id = string<br/>    subnets = object({<br/>      public = list(object({<br/>        name      = string<br/>        subnet_id = string<br/>        az        = string<br/>        az_id     = string<br/>      }))<br/>      private = optional(list(object({<br/>        name      = string<br/>        subnet_id = string<br/>        az        = string<br/>        az_id     = string<br/>      })), [])<br/>    })<br/>  })</pre> | n/a | yes |
| <a name="input_use_fips_endpoint"></a> [use\_fips\_endpoint](#input\_use\_fips\_endpoint) | Use aws FIPS endpoints | `bool` | `false` | no |
| <a name="input_waf"></a> [waf](#input\_waf) | Web Application Firewall (WAF) configuration.<br/>    {<br/>      enabled         = Whether WAF is enabled (true/false).<br/>      override\_action = (Optional) Override action when a rule matches (default: "none").<br/><br/>      rules = List of WAF rules to apply.<br/>      [{<br/>        name        = Rule name.<br/>        vendor\_name = Name of the rule vendor (e.g., "AWS").<br/>        priority    = Rule priority.<br/>        allow       = (Optional) List of conditions to allow.<br/>        block       = (Optional) List of conditions to block.<br/>        captcha     = (Optional) List of CAPTCHA challenge conditions.<br/>        challenge   = (Optional) List of challenge conditions.<br/>        count       = (Optional) List of conditions to count (log only).<br/>      }]<br/><br/>      rate\_limit = Rate-based rule configuration.<br/>      {<br/>        enabled = Whether rate limiting is enabled (true/false).<br/>        limit   = Number of requests per 5-minute period before rate limiting.<br/>        action  = Action to take when limit is exceeded ("block", "count", etc.).<br/>      }<br/><br/>      block\_forwarder\_header = Configuration for header injection on blocked requests.<br/>      {<br/>        enabled = Whether to inject a block forwarder header (true/false).<br/>      }<br/>    } | <pre>object({<br/>    enabled         = bool<br/>    override_action = optional(string, "none")<br/>    rules = list(object({<br/>      name        = string<br/>      vendor_name = string<br/>      priority    = number<br/>      allow       = optional(list(string), [])<br/>      block       = optional(list(string), [])<br/>      captcha     = optional(list(string), [])<br/>      challenge   = optional(list(string), [])<br/>      count       = optional(list(string), [])<br/>    }))<br/>    rate_limit = object({<br/>      enabled = bool<br/>      limit   = number<br/>      action  = string<br/>    })<br/>    block_forwarder_header = object({<br/>      enabled = bool<br/>    })<br/>  })</pre> | n/a | yes |

## Outputs

| Name | Description |
|------|-------------|
| <a name="output_info"></a> [info](#output\_info) | Load Balancers Info |
<!-- END_TF_DOCS -->
