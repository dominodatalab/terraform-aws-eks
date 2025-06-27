locals {
  endpoint_services = { for service in var.privatelink.vpc_endpoint_services : service.name => { private_dns : service.private_dns, supported_regions : service.supported_regions } }
}

data "aws_route53_zone" "hosted" {
  name         = var.privatelink.route53_hosted_zone_name
  private_zone = false
}

resource "aws_vpc_endpoint_service" "vpc_endpoint_services" {
  for_each = local.endpoint_services

  acceptance_required        = false
  network_load_balancer_arns = [var.lb_arns[each.value.lb_name]]

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
