locals {
  global_accelerator_hosted_zone_id = var.use_fips_endpoint ? "Z2BJ6XQ5FK7U4H" : "Z018824593QZ67JH632G" # Fixed Hosted Zone ID for Global Accelerator

  create_global_accelerator = length(local.lbs_with_ddos_protection) > 0

  create_dns_records = local.create_global_accelerator && var.fqdn != ""

  lb_dns_records = local.create_dns_records ? [
    {
      name = var.fqdn
      type = "A"
    },
    {
      name = var.fqdn
      type = "AAAA"
    },
    {
      name = "*.${var.fqdn}"
      type = "A"
    },
    {
      name = "*.${var.fqdn}"
      type = "AAAA"
    },
    {
      name = "apps-${var.fqdn}"
      type = "A"
    },
    {
      name = "apps-${var.fqdn}"
      type = "AAAA"
    }
  ] : []
}

data "aws_route53_zone" "hosted" {
  name         = var.hosted_zone_name
  private_zone = false
}

resource "aws_globalaccelerator_accelerator" "main_accelerator" {
  count = local.create_global_accelerator ? 1 : 0

  name            = "${var.deploy_id}-accelerator"
  enabled         = true
  ip_address_type = "IPV4"

  attributes {
    flow_logs_enabled   = var.flow_logs.enabled
    flow_logs_s3_bucket = var.flow_logs.s3_bucket
    flow_logs_s3_prefix = var.flow_logs.s3_prefix
  }
}

resource "aws_globalaccelerator_listener" "listener" {
  for_each        = local.lbs_with_ddos_protection
  accelerator_arn = aws_globalaccelerator_accelerator.main_accelerator[0].id
  protocol        = "TCP"

  dynamic "port_range" {
    for_each = distinct([
      for listener in each.value.listeners : listener.port
    ])
    content {
      from_port = port_range.value
      to_port   = port_range.value
    }
  }
}

resource "aws_globalaccelerator_endpoint_group" "endpoint_group" {
  for_each = local.lbs_with_ddos_protection

  listener_arn = aws_globalaccelerator_listener.listener[each.key].id

  endpoint_configuration {
    endpoint_id                    = aws_lb.load_balancers[each.key].arn
    client_ip_preservation_enabled = true
    weight                         = 128
  }
}

resource "aws_route53_record" "lbs_dns_records" {
  for_each = { for idx, rec in local.lb_dns_records : "${rec.name}_${rec.type}" => rec }

  zone_id = data.aws_route53_zone.hosted.zone_id
  name    = each.value.name
  type    = each.value.type

  alias {
    name                   = aws_globalaccelerator_accelerator.main_accelerator[0].dns_name
    zone_id                = local.global_accelerator_hosted_zone_id
    evaluate_target_health = true
  }
}
