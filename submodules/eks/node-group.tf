
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
  vpc_id      = var.vpc_id

  lifecycle {
    create_before_destroy = true
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

resource "aws_security_group_rule" "efs" {
  security_group_id        = var.efs_security_group
  protocol                 = "tcp"
  from_port                = 2049
  to_port                  = 2049
  type                     = "ingress"
  description              = "EFS access"
  source_security_group_id = aws_security_group.eks_nodes.id
}

locals {
  taint_effects = {
    NO_SCHEDULE        = "NoSchedule"
    NO_EXECUTE         = "NoExecute"
    PREFER_NO_SCHEDULE = "PreferNoSchedule"
  }

  node_groups = merge(var.additional_node_groups, var.default_node_groups)
  node_groups_per_zone = flatten([
    for ng_name, ng in local.node_groups : [
      for sb_name, sb in var.private_subnets : {
        ng_name    = ng_name
        sb_name    = sb_name
        subnet     = sb
        node_group = ng
      }
    ]
  ])
}

data "aws_ec2_instance_type" "all" {
  for_each      = toset([for ng in local.node_groups : ng.instance_type])
  instance_type = each.value
}

resource "aws_launch_template" "node_groups" {
  for_each                = local.node_groups
  name                    = "${local.eks_cluster_name}-${each.key}"
  disable_api_termination = false
  instance_type           = each.value.instance_type
  key_name                = var.ssh_pvt_key_path
  vpc_security_group_ids  = [aws_security_group.eks_nodes.id]
  image_id                = each.value.ami

  block_device_mappings {
    device_name = "/dev/xvda"

    ebs {
      delete_on_termination = true
      encrypted             = true
      volume_size           = each.value.volume.size
      volume_type           = each.value.volume.type
    }
  }

  metadata_options {
    http_endpoint               = "enabled"
    http_put_response_hop_limit = "2"
    http_tokens                 = "required"
  }

  # add any tagtag_specifications and additional ones are magically created
  tag_specifications {
    resource_type = "instance"
    tags = {
      "Name" = "${local.eks_cluster_name}-${each.key}"
    }
  }

  tag_specifications {
    resource_type = "volume"
    tags = {
      "Name" = "${local.eks_cluster_name}-${each.key}"
    }
  }

  depends_on = [
    aws_security_group_rule.node,
    aws_iam_role_policy_attachment.aws_eks_nodes,
    aws_iam_role_policy_attachment.custom_eks_nodes,
  ]
}

resource "aws_eks_node_group" "node_groups" {
  for_each        = { for ngz in local.node_groups_per_zone : "${ngz.ng_name}-${ngz.sb_name}" => ngz }
  cluster_name    = aws_eks_cluster.this.name
  node_group_name = "${local.eks_cluster_name}-${each.key}"
  node_role_arn   = aws_iam_role.eks_nodes.arn
  subnet_ids      = [each.value.subnet]
  scaling_config {
    min_size     = each.value.node_group.min_per_az
    max_size     = each.value.node_group.max_per_az
    desired_size = each.value.node_group.desired_per_az
  }

  ami_type = each.value.node_group.ami != null ? "CUSTOM" : (length(data.aws_ec2_instance_type.all[each.value.node_group.instance_type].gpus) == 0 ? "AL2_x86_64" : "AL2_x86_64_GPU")
  launch_template {
    id      = aws_launch_template.node_groups[each.value.ng_name].id
    version = aws_launch_template.node_groups[each.value.ng_name].latest_version
  }

  labels = merge(each.value.node_group.labels, {
    "dominodatalab.com/domino-node" = true
  })

  dynamic "taint" {
    for_each = each.value.node_group.taints
    content {
      key    = taint.value.key
      value  = taint.value.value
      effect = taint.value.effect
    }
  }

  lifecycle {
    ignore_changes = [
      scaling_config[0].desired_size,
    ]
  }
}
