## EKS Nodes
data "aws_iam_policy_document" "eks_nodes" {
  statement {
    actions = ["sts:AssumeRole"]

    principals {
      type        = "Service"
      identifiers = ["ec2.${local.dns_suffix}"]
    }
  }
}

resource "aws_iam_role" "eks_nodes" {
  name               = "${local.eks_cluster_name}-eks-nodes"
  assume_role_policy = data.aws_iam_policy_document.eks_nodes.json
}

resource "aws_security_group" "eks_nodes" {
  name        = "${local.eks_cluster_name}-nodes"
  description = "EKS cluster Nodes security group"
  vpc_id      = var.network_info.vpc_id

  lifecycle {
    create_before_destroy = true
    ignore_changes = [
      name,
      description
    ]
  }
  tags = {
    "Name"                                            = "${local.eks_cluster_name}-eks-nodes"
    "kubernetes.io/cluster/${local.eks_cluster_name}" = "owned"
  }
}

resource "aws_security_group_rule" "node" {
  for_each = local.node_security_group_rules

  # Required
  security_group_id = aws_security_group.eks_nodes.id
  protocol          = each.value.protocol
  from_port         = each.value.from_port
  to_port           = each.value.to_port
  type              = each.value.type
  description       = each.value.description
  cidr_blocks       = try(each.value.cidr_blocks, null)
  self              = try(each.value.self, null)
  source_security_group_id = try(
    each.value.source_security_group_id,
    try(each.value.source_cluster_security_group, false) ? aws_security_group.eks_cluster.id : null
  )
}

moved {
  from = aws_security_group_rule.efs
  to   = aws_security_group_rule.shared_storage["efs_2049_2049"]
}

### FSX

locals {
  shared_storage_type = var.fsx != null ? "fsx" : "efs"
  inbound_rules = local.shared_storage_type == "fsx" ? {
    rules = [
      { protocol = "all", from_port = 0, to_port = 65535, description = "All traffic from EKS nodes." },
    ]
    security_group_id = var.fsx.filesystem.security_group_id
    } : {
    rules = [
      { protocol = "tcp", from_port = 2049, to_port = 2049, description = "EFS access" }
    ]
    security_group_id = var.efs_security_group
  }
}

resource "aws_security_group_rule" "shared_storage" {
  for_each = { for r in local.inbound_rules.rules : "${local.shared_storage_type}_${r.from_port}_${r.to_port}" => r }

  security_group_id        = local.inbound_rules.security_group_id
  source_security_group_id = aws_security_group.eks_nodes.id
  protocol                 = each.value.protocol
  from_port                = each.value.from_port
  to_port                  = each.value.to_port
  type                     = "ingress"
  description              = each.value.description
}
