locals {
  global_accelerator_hosted_zone_id = "Z2BJ6XQ5FK7U4H" # Fixed Hosted Zone ID for Global Accelerator

  lbs_with_ddos = {
    for lb in var.load_balancers :
    lb.name => lb if lb.ddos_protection
  }

  create_global_accelerator = length(local.lbs_with_ddos) > 0

  create_dns_records = local.create_global_accelerator && var.fqdn != ""
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
  for_each        = local.lbs_with_ddos
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
  for_each = local.lbs_with_ddos

  listener_arn = aws_globalaccelerator_listener.listener[each.key].id

  endpoint_configuration {
    endpoint_id                    = aws_lb.load_balancers[each.key].arn
    client_ip_preservation_enabled = true
    weight                         = 128
  }
}

resource "aws_route53_record" "root_record_type_a" {
  count = local.create_dns_records ? 1 : 0

  zone_id = data.aws_route53_zone.hosted.zone_id
  name    = var.fqdn
  type    = "A"
  alias {
    name                   = aws_globalaccelerator_accelerator.main_accelerator[0].dns_name
    zone_id                = local.global_accelerator_hosted_zone_id
    evaluate_target_health = true
  }
}

resource "aws_route53_record" "root_record_type_aaaa" {
  count = local.create_dns_records ? 1 : 0

  zone_id = data.aws_route53_zone.hosted.zone_id
  name    = var.fqdn
  type    = "AAAA"
  alias {
    name                   = aws_globalaccelerator_accelerator.main_accelerator[0].dns_name
    zone_id                = local.global_accelerator_hosted_zone_id
    evaluate_target_health = true
  }
}

# Record A (wildcard)
resource "aws_route53_record" "wildcard_record_type_a" {
  count = local.create_dns_records ? 1 : 0

  zone_id = data.aws_route53_zone.hosted.zone_id
  name    = "*.${var.fqdn}"
  type    = "A"
  alias {
    name                   = aws_globalaccelerator_accelerator.main_accelerator[0].dns_name
    zone_id                = local.global_accelerator_hosted_zone_id
    evaluate_target_health = true
  }
}

# Record AAAA (wildcard)
resource "aws_route53_record" "wildcard_record_type_aaaa" {
  count = local.create_dns_records ? 1 : 0

  zone_id = data.aws_route53_zone.hosted.zone_id
  name    = "*.${var.fqdn}"
  type    = "AAAA"
  alias {
    name                   = aws_globalaccelerator_accelerator.main_accelerator[0].dns_name
    zone_id                = local.global_accelerator_hosted_zone_id
    evaluate_target_health = true
  }
}

# Record A (apps)
resource "aws_route53_record" "wildcard_record_type_a" {
  count = local.create_dns_records ? 1 : 0

  zone_id = data.aws_route53_zone.hosted.zone_id
  name    = "apps-${var.fqdn}"
  type    = "A"
  alias {
    name                   = aws_globalaccelerator_accelerator.main_accelerator[0].dns_name
    zone_id                = local.global_accelerator_hosted_zone_id
    evaluate_target_health = true
  }
}

# Record AAAA (apps)
resource "aws_route53_record" "wildcard_record_type_aaaa" {
  count = local.create_dns_records ? 1 : 0

  zone_id = data.aws_route53_zone.hosted.zone_id
  name    = "apps-${var.fqdn}"
  type    = "AAAA"
  alias {
    name                   = aws_globalaccelerator_accelerator.main_accelerator[0].dns_name
    zone_id                = local.global_accelerator_hosted_zone_id
    evaluate_target_health = true
  }
}