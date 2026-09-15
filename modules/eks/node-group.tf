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
  # trivy:ignore:AWS-0104 EKS nodes require unrestricted egress for container images, AWS services, and external dependencies
  cidr_blocks = try(each.value.cidr_blocks, null)
  self        = try(each.value.self, null)
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

locals {
  # A cluster plan reads storage_info out of infra.tfstate on disk, not live, so on a dry run it
  # can be reading state written before netapp_base existed: netapp populated, netapp_base null.
  # Without a fallback this rule plans as a destroy with nothing replacing it, on every netapp
  # deployment. On state that old netapp IS the base filesystem, so use it.
  #
  # Gated on there being no additional filesystems for two reasons. A state that predates
  # netapp_base also predates netapp_additional, so the gate is free there. And after retire_base
  # netapp_base is legitimately null while netapp resolves to the replacement, whose security group
  # netapp_additional already opens; falling back in that state would re-create the duplicate rule
  # that keying off netapp_base was meant to avoid.
  #
  # Written with nullness checks and a map length rather than try() on the id: try() yields an
  # unknown whenever the value it reads is not wholly known, and count cannot take an unknown.
  netapp_base_is_legacy_output = var.storage_info != null ? (
    var.storage_info.netapp_base == null
    && var.storage_info.netapp != null
    && length(coalesce(var.storage_info.netapp_additional, {})) == 0
  ) : false
}

# Node access to the BASE filesystem. Deliberately keyed off netapp_base rather than netapp:
# netapp follows storage.netapp.active, so on a cutover (active != "base") it would point this
# rule at the replacement filesystem's security group -- which netapp_additional below already
# opens. AWS rejects the second, identical rule with InvalidPermission.Duplicate, and the base
# filesystem is left with no node access even though it still exists. Reachability is per
# filesystem; `active` only selects which one Trident uses.
resource "aws_security_group_rule" "netapp" {
  count = var.storage_info != null ? (
    var.storage_info.netapp_base != null || local.netapp_base_is_legacy_output ? 1 : 0
  ) : 0
  security_group_id = (
    var.storage_info.netapp_base != null
    ? var.storage_info.netapp_base.filesystem.security_group_id
    : var.storage_info.netapp.filesystem.security_group_id
  )
  protocol                 = "-1"
  from_port                = 0
  to_port                  = 65535
  type                     = "ingress"
  description              = "Netapp access from EKS nodes."
  source_security_group_id = aws_security_group.eks_nodes.id
}

resource "aws_security_group_rule" "netapp_additional" {
  for_each                 = var.storage_info != null ? coalesce(var.storage_info.netapp_additional, {}) : {}
  security_group_id        = each.value.filesystem.security_group_id
  protocol                 = "-1"
  from_port                = 0
  to_port                  = 65535
  type                     = "ingress"
  description              = "Netapp access from EKS nodes (${each.key})."
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
  count      = var.kms_info.provided_key ? 1 : 0
  role       = aws_iam_role.eks_nodes.name
  policy_arn = local.kms_key_policy_arn
}
