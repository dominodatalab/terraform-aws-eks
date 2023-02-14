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
  subnets_by_az = {
    for sb_name, sb in var.private_subnets :
    sb.az => sb_name
  }

  node_groups_per_zone = flatten([
    for ng_name, ng in var.node_groups :
    ng.availability_zones != null ?

    [for az in ng.availability_zones : {
      ng_name    = ng_name
      sb_name    = local.subnets_by_az[az]
      subnet     = var.private_subnets[local.subnets_by_az[az]]
      node_group = ng
    }]

    :

    [for sb_name, sb in slice(var.private_subnets, 0, ng.number_of_azs != null ? ng.number_of_azs : length(var.private_subnets)) : {
      ng_name    = ng_name
      sb_name    = sb_name
      subnet     = sb
      node_group = ng
    }]
  ])
  node_groups_by_name = { for ngz in local.node_groups_per_zone : "${ngz.ng_name}-${ngz.sb_name}" => ngz }
}

data "aws_default_tags" "this" {}

resource "aws_launch_template" "node_groups" {
  for_each                = var.node_groups
  name                    = "${local.eks_cluster_name}-${each.key}"
  disable_api_termination = false
  key_name                = var.ssh_key_pair_name
  user_data = each.value.ami == null ? each.value.gpu ? base64encode(file("${path.module}/templates/gpu_cert_setup.tpl")) : null : base64encode(templatefile(
    "${path.module}/templates/linux_user_data.tpl",
    {
      # https://docs.aws.amazon.com/eks/latest/userguide/launch-templates.html#launch-template-custom-ami
      # Required to bootstrap node
      cluster_name        = aws_eks_cluster.this.name
      cluster_endpoint    = aws_eks_cluster.this.endpoint
      cluster_auth_base64 = aws_eks_cluster.this.certificate_authority[0].data
      # Optional
      cluster_service_ipv4_cidr = aws_eks_cluster.this.kubernetes_network_config[0].service_ipv4_cidr != null ? aws_eks_cluster.this.kubernetes_network_config[0].service_ipv4_cidr : ""
      bootstrap_extra_args      = each.value.bootstrap_extra_args
      pre_bootstrap_user_data   = ""
      post_bootstrap_user_data  = ""
  }))
  vpc_security_group_ids = [aws_security_group.eks_nodes.id]
  image_id               = each.value.ami

  block_device_mappings {
    device_name = "/dev/xvda"

    ebs {
      delete_on_termination = true
      encrypted             = true
      volume_size           = each.value.volume.size
      volume_type           = each.value.volume.type
      kms_key_id            = var.node_groups_kms_key
    }
  }

  metadata_options {
    http_endpoint               = "enabled"
    http_put_response_hop_limit = "2"
    http_tokens                 = "required"
  }

  # add any tag_specifications and additional ones are magically created
  dynamic "tag_specifications" {
    for_each = toset(["instance", "volume"])
    content {
      resource_type = tag_specifications.value
      tags = merge(data.aws_default_tags.this.tags, each.value.tags, {
        "Name" = "${local.eks_cluster_name}-${each.key}"
      })
    }
  }

  depends_on = [
    aws_security_group_rule.node,
    aws_iam_role_policy_attachment.aws_eks_nodes,
    aws_iam_role_policy_attachment.custom_eks_nodes,
  ]
}

resource "aws_eks_node_group" "node_groups" {
  depends_on      = [module.k8s_setup]
  for_each        = local.node_groups_by_name
  cluster_name    = aws_eks_cluster.this.name
  node_group_name = "${local.eks_cluster_name}-${each.key}"
  node_role_arn   = aws_iam_role.eks_nodes.arn
  subnet_ids      = [each.value.subnet.subnet_id]
  scaling_config {
    min_size     = each.value.node_group.min_per_az
    max_size     = each.value.node_group.max_per_az
    desired_size = each.value.node_group.desired_per_az
  }

  ami_type       = each.value.node_group.ami != null ? "CUSTOM" : each.value.node_group.gpu ? "AL2_x86_64_GPU" : "AL2_x86_64"
  capacity_type  = each.value.node_group.spot ? "SPOT" : "ON_DEMAND"
  instance_types = each.value.node_group.instance_types
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

  tags = each.value.node_group.tags

  lifecycle {
    ignore_changes = [
      scaling_config[0].desired_size,
    ]
  }
}

locals {
  asg_tags = flatten([for name, v in local.node_groups_by_name : [
    {
      name  = name
      key   = "k8s.io/cluster-autoscaler/node-template/label/topology.ebs.csi.aws.com/zone"
      value = v.subnet.az
    },
    {
      name  = name
      key   = "k8s.io/cluster-autoscaler/node-template/resources/smarter-devices/fuse"
      value = "20"
    },
    # this is necessary until cluster-autoscaler v1.24, labels and taints are from the nodegroup
    # https://github.com/kubernetes/autoscaler/commit/b4cadfb4e25b6660c41dbe2b73e66e9a2f3a2cc9
    [for lkey, lvalue in v.node_group.labels : [
      {
        name  = name
        key   = format("k8s.io/cluster-autoscaler/node-template/label/%v", lkey)
        value = lvalue
    }]],
    [for t in v.node_group.taints : [
      {
        name  = name
        key   = format("k8s.io/cluster-autoscaler/node-template/taint/%v", t.key)
        value = "${t.value == null ? "" : t.value}:${local.taint_effect_map[t.effect]}"
      }
    ]]
  ]])

  taint_effect_map = {
    NO_SCHEDULE        = "NoSchedule"
    NO_EXECUTE         = "NoExecute"
    PREFER_NO_SCHEDULE = "PreferNoSchedule"
  }
}

# https://github.com/kubernetes/autoscaler/blob/master/cluster-autoscaler/cloudprovider/aws/README.md#auto-discovery-setup
resource "aws_autoscaling_group_tag" "tag" {
  for_each = { for info in local.asg_tags : "${info.name}-${info.key}" => info }

  autoscaling_group_name = aws_eks_node_group.node_groups[each.value.name].resources[0].autoscaling_groups[0].name

  tag {
    key                 = each.value.key
    value               = each.value.value
    propagate_at_launch = false
  }
}
