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
      description,
      tags
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

moved {
  from = aws_security_group_rule.shared_storage["efs_2049_2049"]
  to   = aws_security_group_rule.efs[0]
}

resource "aws_security_group_rule" "efs" {
  count = var.storage_info != null ? (
    var.storage_info.efs != null ? 1 : 0
  ) : 0
  security_group_id        = var.storage_info.efs.security_group_id
  protocol                 = "tcp"
  from_port                = 2049
  to_port                  = 2049
  type                     = "ingress"
  description              = "EFS access"
  source_security_group_id = aws_security_group.eks_nodes.id
}

resource "aws_security_group_rule" "netapp" {
  count = var.storage_info != null ? (
    var.storage_info.netapp != null ? 1 : 0
  ) : 0
  security_group_id        = var.storage_info.netapp.filesystem.security_group_id
  protocol                 = "-1"
  from_port                = 0
  to_port                  = 65535
  type                     = "ingress"
  description              = "Netapp access from EKS nodes."
  source_security_group_id = aws_security_group.eks_nodes.id
}

resource "aws_security_group_rule" "ecr_endpoint" {
  count                    = var.network_info.ecr_endpoint != null ? 1 : 0
  security_group_id        = var.network_info.ecr_endpoint.security_group_id
  protocol                 = "tcp"
  from_port                = 443
  to_port                  = 443
  type                     = "ingress"
  description              = "ECR Endpoint access from EKS nodes."
  source_security_group_id = aws_security_group.eks_nodes.id
}

resource "aws_security_group_rule" "s3_endpoint" {
  count                    = var.network_info.s3_endpoint != null ? 1 : 0
  security_group_id        = var.network_info.s3_endpoint.security_group_id
  protocol                 = "tcp"
  from_port                = 443
  to_port                  = 443
  type                     = "ingress"
  description              = "S3 Endpoint access from EKS nodes."
  source_security_group_id = aws_security_group.eks_nodes.id
}

resource "aws_iam_role_policy_attachment" "attach_provided_key_policy_to_eks_nodes" {
  count = (
    var.kms_info != null && var.kms_info.key_policy_arn != null && var.kms_info.key_policy_arn != ""
  ) ? 1 : 0
  role       = aws_iam_role.eks_nodes.name
  policy_arn = local.kms_key_policy_arn
}