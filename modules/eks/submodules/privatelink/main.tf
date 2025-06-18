locals {
  endpoint_services = { for service in var.privatelink.vpc_endpoint_services : service.name => { private_dns : service.private_dns, supported_regions : service.supported_regions } }

  listeners = distinct(flatten([
    for service in var.privatelink.vpc_endpoint_services : [
      for port in service.ports : {
        service  = service.name
        port     = port
        cert_arn = service.cert_arn
      }
    ]
  ]))
}

data "aws_route53_zone" "hosted" {
  name         = var.privatelink.route53_hosted_zone_name
  private_zone = false
}

resource "aws_security_group" "nlb_sg" {
  name        = "${var.deploy_id}-nlb-sg"
  description = "NLB Security Group"
  vpc_id      = var.network_info.vpc_id

  egress {
    description = "All traffic"
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = [var.network_info.vpc_cidrs]
  }
}

resource "aws_lb" "nlbs" {
  for_each = local.endpoint_services

  name               = "${var.deploy_id}-${each.key}"
  internal           = true
  load_balancer_type = "network"

  enforce_security_group_inbound_rules_on_private_link_traffic = "off"

  security_groups = [aws_security_group.nlb_sg.id]
  subnets         = [for subnet in var.network_info.subnets.private : subnet.subnet_id]

  enable_deletion_protection       = false
  enable_cross_zone_load_balancing = true

  access_logs {
    bucket  = var.privatelink.monitoring_bucket
    enabled = true
  }
}

resource "aws_lb_target_group" "target_groups" {
  for_each = { for entry in local.listeners : "${entry.service}.${entry.port}" => entry }

  name     = "${var.deploy_id}-${substr(each.value.service, 0, 9)}-${each.value.port}"
  port     = 80 # Not used but required
  protocol = "TCP"
  vpc_id   = var.network_info.vpc_id

  tags = {
    "service_name" = each.value.service
    "service_port" = each.value.port
  }
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
    target_group_arn = aws_lb_target_group.target_groups[each.key].arn
  }
}

resource "aws_vpc_endpoint_service" "vpc_endpoint_services" {
  for_each = local.endpoint_services

  acceptance_required        = false
  network_load_balancer_arns = [aws_lb.nlbs[each.key].arn]

  private_dns_name = each.value.private_dns

  tags = {
    "Name" = "${var.deploy_id}-${each.key}"
  }

  supported_regions = each.value.supported_regions
}

resource "aws_route53_record" "service_endpoint_private_dns_verification" {
  for_each = local.endpoint_services

  zone_id = data.aws_route53_zone.hosted.zone_id
  name    = each.value.private_dns
  type    = "TXT"
  ttl     = 1800
  records = [
    aws_vpc_endpoint_service.vpc_endpoint_services[each.key].private_dns_name_configuration[0].value
  ]
}
