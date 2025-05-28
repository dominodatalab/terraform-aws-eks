locals {
  lbs = {
    for lb in var.load_balancers : lb.name => lb
  }

  listeners = {
    for item in flatten([
      for lb in var.load_balancers : [
        for listener in lb.listeners : {
          key        = "${lb.name}.${listener.port}"
          lb_name    = lb.name
          port       = listener.port
          protocol   = listener.protocol
          ssl_policy = lookup(listener, "ssl_policy", null)
          cert_arn   = lookup(listener, "cert_arn", null)
        }
      ]
    ]) : item.key => item
  }
}

resource "aws_lb" "load_balancers" {
  for_each = local.lbs

  name               = "${var.deploy_id}-${each.key}"
  internal           = each.value.internal
  load_balancer_type = each.value.type
  security_groups    = [aws_security_group.lb_security_groups[each.key].id]
  subnets            = [for subnet in(each.value.internal ? var.network_info.subnets.private : var.network_info.subnets.public) : subnet.subnet_id]

  enable_deletion_protection = false

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