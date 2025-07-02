resource "aws_lb_target_group" "lb_target_groups" {
  for_each = local.listeners

  name = "${var.deploy_id}-${substr(each.value.lb_name, 0, 9)}-${each.value.port}"

  port        = each.value.port
  protocol    = each.value.protocol
  target_type = "instance"
  vpc_id      = var.network_info.vpc_id

  dynamic "health_check" {
    for_each = contains(["HTTP", "HTTPS"], each.value.protocol) ? [1] : []
    content {
      path     = "/healthz"
      protocol = each.value.protocol
      matcher  = "200"
    }
  }
}
