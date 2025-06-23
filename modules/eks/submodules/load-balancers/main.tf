locals {
  lbs = {
    for lb in var.load_balancers : lb.name => lb
  }

  albs = {
    for lb in var.load_balancers : lb.name => lb
    if lb.type == "application"
  }

  lbs_with_ddos_protection = {
    for lb in var.load_balancers : lb.name => lb
    if try(lb.ddos_protection, true)
  }

  listeners = {
    for item in flatten([
      for lb in var.load_balancers : [
        for listener in lb.listeners : {
          key             = "${lb.name}-${listener.name}"
          lb_name         = lb.name
          ddos_protection = lb.ddos_protection
          port            = listener.port
          protocol        = listener.protocol
          ssl_policy      = lookup(listener, "ssl_policy", null)
          cert_arn        = lookup(listener, "cert_arn", null)
        }
      ]
    ]) : item.key => item
  }

  listeners_ddos_protected = {
    for listener in local.listeners :
    listener.key => {
      lb_name = listener.lb_name
      port    = listener.port
    }
    if listener.ddos_protection
  }
}

resource "aws_lb" "load_balancers" {
  # checkov:skip=CKV_AWS_131:ALB does not drop HTTP headers. Skipping to avoid breaking changes
  # checkov:skip=CKV2_AWS_76:Ensure AWS ALB attached WAFv2 WebACL is configured with AMR for Log4j Vulnerability. WAF has dynamic rules for this

  for_each = local.lbs

  name               = "${var.deploy_id}-${each.key}"
  internal           = each.value.internal
  load_balancer_type = each.value.type
  security_groups    = [aws_security_group.lb_security_groups[each.key].id]
  subnets            = [for subnet in(each.value.internal ? var.network_info.subnets.private : var.network_info.subnets.public) : subnet.subnet_id]

  enforce_security_group_inbound_rules_on_private_link_traffic = "off"

  enable_deletion_protection       = false
  enable_cross_zone_load_balancing = true

  access_logs {
    enabled = var.access_logs.enabled
    bucket  = var.access_logs.s3_bucket
    prefix  = var.access_logs.s3_prefix
  }

  connection_logs {
    enabled = var.connection_logs.enabled
    bucket  = var.connection_logs.s3_bucket
    prefix  = var.connection_logs.s3_prefix
  }

  tags = {
    Name = "${var.deploy_id}-${each.key}"
  }
}

resource "aws_lb_listener" "load_balancer_listener" {
  # checkov:skip=CKV_AWS_103:AWS Load Balancer is not using TLS 1.2. ssl_policy is provided as input
  # checkov:skip=CKV_AWS_2:AWS Elastic Load Balancer v2 (ELBv2) listener that allow connection requests over HTTP. Skipping to avoid breaking changes

  for_each = local.listeners

  load_balancer_arn = aws_lb.load_balancers[each.value.lb_name].arn
  port              = each.value.port
  protocol          = each.value.protocol
  ssl_policy        = contains(["HTTPS", "TLS"], each.value.protocol) ? each.value.ssl_policy : null
  certificate_arn   = contains(["HTTPS", "TLS"], each.value.protocol) ? each.value.cert_arn : null

  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.lb_target_groups[each.key].arn
  }
}