resource "aws_security_group" "alb_sg" {
  for_each = local.albs

  name        = "${var.deploy_id}-${each.key}-sg"
  description = "Security Group for ${each.key}"
  vpc_id      = var.network_info.vpc_id

  tags = {
    Name = "${var.deploy_id}-${each.key}-sg"
  }
}

resource "aws_security_group" "nlb_sg" {
  for_each = local.nlbs

  name        = "${var.deploy_id}-${each.key}-sg"
  description = "Security Group for ${each.key}"
  vpc_id      = var.network_info.vpc_id

  tags = {
    Name = "${var.deploy_id}-${each.key}-sg"
  }
}