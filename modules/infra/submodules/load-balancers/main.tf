locals {
  lbs = {
    for lb in var.load_balancers : lb.name => lb
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