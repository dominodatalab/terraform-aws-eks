resource "aws_security_group" "lb_security_groups" {
  for_each = local.lbs

  name        = "${var.deploy_id}-${each.key}-sg"
  description = "Security Group for ${each.key}"
  vpc_id      = var.network_info.vpc_id

  tags = {
    Name = "${var.deploy_id}-${each.key}-sg"
  }
}