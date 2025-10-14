resource "aws_lb_target_group" "lb_target_groups" {
  for_each = local.listeners

  // Note to self: htf to deal with low 32 character name limit
  name = "${var.deploy_id}-${substr(each.value.lb_name, 0, 9)}-${each.value.port}${each.value.tg_protocol_version != null ? "-${each.value.tg_protocol_version}" : ""}"

  port             = each.value.port
  protocol         = each.value.tg_protocol
  protocol_version = each.value.tg_protocol_version
  target_type      = "instance"
  vpc_id           = var.network_info.vpc_id

  dynamic "health_check" {
    for_each = contains(["HTTP", "HTTPS"], each.value.tg_protocol) ? [1] : []
    content {
      path     = "/healthz"
      protocol = each.value.tg_protocol
      matcher  = "200"
    }
  }

  lifecycle {
    create_before_destroy = true
  }
}
