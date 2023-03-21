locals {
  bastion_eks_security_group_rules = {
    bastion_to_eks_api = {
      description              = "To ${local.eks_cluster_name}:443"
      protocol                 = "tcp"
      from_port                = "443"
      to_port                  = "443"
      type                     = "egress"
      security_group_id        = try(var.bastion_info.security_group_id, null)
      source_security_group_id = aws_security_group.eks_cluster.id
    }
    bastion_to_eks_nodes_ssh = {
      description              = "To eks nodes over ssh"
      protocol                 = "tcp"
      from_port                = "22"
      to_port                  = "22"
      type                     = "egress"
      security_group_id        = try(var.bastion_info.security_group_id, null)
      source_security_group_id = aws_security_group.eks_nodes.id
    }
    eks_api_from_bastion = {
      description              = "From Bastion over https"
      protocol                 = "tcp"
      from_port                = "443"
      to_port                  = "443"
      type                     = "ingress"
      security_group_id        = aws_security_group.eks_cluster.id
      source_security_group_id = try(var.bastion_info.security_group_id, null)
    }
    eks_nodes_ssh_from_bastion = {
      description              = "From Bastion over ssh"
      protocol                 = "tcp"
      from_port                = "22"
      to_port                  = "22"
      type                     = "ingress"
      security_group_id        = aws_security_group.eks_nodes.id
      source_security_group_id = try(var.bastion_info.security_group_id, null)
    }
  }
}

resource "aws_security_group_rule" "bastion_eks" {
  for_each = { for k, v in local.bastion_eks_security_group_rules : k => v if var.bastion_info != null }

  security_group_id        = each.value.security_group_id
  protocol                 = each.value.protocol
  from_port                = each.value.from_port
  to_port                  = each.value.to_port
  type                     = each.value.type
  description              = each.value.description
  source_security_group_id = each.value.source_security_group_id
}
