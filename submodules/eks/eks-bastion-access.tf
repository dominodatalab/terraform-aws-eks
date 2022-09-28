resource "aws_security_group_rule" "bastion_eks" {
  for_each = { for k, v in local.bastion_eks_security_group_rules : k => v if var.create_bastion_sg }

  security_group_id        = each.value.security_group_id
  protocol                 = each.value.protocol
  from_port                = each.value.from_port
  to_port                  = each.value.to_port
  type                     = each.value.type
  description              = each.value.description
  source_security_group_id = each.value.source_security_group_id
}
