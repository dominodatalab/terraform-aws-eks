resource "aws_security_group" "lb_security_groups" {
  for_each = local.lbs

  name        = "${var.deploy_id}-${each.key}-sg"
  description = "Security Group for ${each.key}"
  vpc_id      = var.network_info.vpc_id

  tags = {
    Name = "${var.deploy_id}-${each.key}-sg"
  }
}

resource "aws_security_group_rule" "lb_ingress_from_global_accelerator" {
  for_each = local.listeners_ddos_protected

  type                     = "ingress"
  from_port                = each.value.port
  to_port                  = each.value.port
  protocol                 = "tcp"
  security_group_id        = aws_security_group.lb_security_groups[each.value.lb_name].id
  source_security_group_id = data.aws_security_group.global_accelerator_sg[0].id
  description              = "Allow access from Global Accelerator"
}

resource "aws_security_group_rule" "lb_ingress_for_public_lbs_without_ddos_protection" {
  for_each = local.public_lbs_without_ddos_protection

  type              = "ingress"
  from_port         = 0
  to_port           = 0
  protocol          = "-1"
  security_group_id = aws_security_group.lb_security_groups[each.value.lb_name].id
  cidr_blocks       = ["0.0.0.0/0"]
  description       = "Allow access from anywhere for public NLB"
}

resource "aws_security_group_rule" "allow_all_from_ddos_lb" {
  for_each = local.lbs

  type                     = "ingress"
  from_port                = 0
  to_port                  = 0
  protocol                 = "-1"
  security_group_id        = var.eks_nodes_security_group_id
  source_security_group_id = aws_security_group.lb_security_groups[each.key].id
  description              = "Allow traffic from load balancer - ${each.key}"
}

resource "aws_security_group_rule" "allow_all_egress" {
  for_each = local.lbs

  type              = "egress"
  from_port         = 0
  to_port           = 0
  protocol          = "-1"
  security_group_id = aws_security_group.lb_security_groups[each.key].id
  cidr_blocks       = ["0.0.0.0/0"]
  description       = "Allow all egress traffic from load balancer - ${each.key}"
}

data "aws_security_group" "global_accelerator_sg" {
  count = local.create_global_accelerator ? 1 : 0

  filter {
    name   = "group-name"
    values = ["GlobalAccelerator"]
  }

  vpc_id = var.network_info.vpc_id

  depends_on = [aws_globalaccelerator_endpoint_group.endpoint_group]
}
