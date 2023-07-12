locals {
  endpoint_services = toset([for service in var.vpc_endpoint_services : service.name])
  
  listeners = distinct(flatten([
    for service in var.vpc_endpoint_services : [
      for port in service.ports : {
        service  = service.name
        port     = port
        cert_arn = service.cert_arn
      }
    ]
  ]))
}

resource "aws_s3_bucket" "lb_logs" {
  bucket = "${var.deploy_id}-lb-logs"
}

resource "aws_lb" "nlbs" {
  for_each = local.endpoint_services

  name               = each.value
  load_balancer_type = "network"

  subnets = [for subnet in aws_subnet.public : subnet.id]

  enable_deletion_protection       = true
  enable_cross_zone_load_balancing = true

  access_logs {
    bucket  = aws_s3_bucket.lb_logs.bucket
    enabled = true
  }
}

resource "aws_lb_target_group" "target_groups" {
  for_each = local.endpoint_services

  name     = each.value
  port     = 80 # Not used but required
  protocol = "TCP"
  vpc_id   = aws_vpc.this[0].id
}

resource "aws_lb_listener" "listeners" {
  for_each = { for entry in local.listeners : "${entry.service}.${entry.port}" => entry }

  load_balancer_arn = aws_lb.nlbs[each.value.service].arn
  port              = each.value.port
  protocol          = "TLS"
  ssl_policy        = "ELBSecurityPolicy-TLS-1-2-2017-01"
  certificate_arn   = each.value.cert_arn

  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.target_groups[each.value.service].arn
  }
}