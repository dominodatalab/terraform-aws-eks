
resource "aws_launch_template" "node_groups" {
  for_each                = local.node_groups
  name                    = "${var.eks_info.cluster.specs.name}-${each.key}"
  disable_api_termination = false
  key_name                = var.ssh_key.key_pair_name
  user_data = each.value.ami == null ? null : base64encode(templatefile(
    "${path.module}/templates/linux_user_data.tpl",
    {
      # https://docs.aws.amazon.com/eks/latest/userguide/launch-templates.html#launch-template-custom-ami
      # Required to bootstrap node
      cluster_name        = var.eks_info.cluster.specs.name
      cluster_endpoint    = var.eks_info.cluster.specs.endpoint
      cluster_auth_base64 = var.eks_info.cluster.specs.certificate_authority[0].data
      # Optional
      cluster_service_ipv4_cidr = var.eks_info.cluster.specs.kubernetes_network_config[0].service_ipv4_cidr != null ? var.eks_info.cluster.specs.kubernetes_network_config[0].service_ipv4_cidr : ""
      bootstrap_extra_args      = each.value.bootstrap_extra_args
      pre_bootstrap_user_data   = ""
      post_bootstrap_user_data  = ""
  }))
  vpc_security_group_ids = [var.eks_info.nodes.security_group_id]
  image_id               = each.value.ami

  block_device_mappings {
    device_name = try(data.aws_ami.custom[each.value.ami].root_device_name, "/dev/xvda")

    ebs {
      delete_on_termination = true
      encrypted             = true
      volume_size           = each.value.volume.size
      volume_type           = each.value.volume.type
      kms_key_id            = var.kms_info.enabled ? var.kms_info.key_arn : null
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
      tags = merge(each.value.instance_tags, each.value.tags, {
        "Name" = "${var.eks_info.cluster.specs.name}-${each.key}"
      })
    }
  }

  lifecycle {
    precondition {
      condition     = length(setsubtract(each.value.availability_zone_ids, data.aws_ec2_instance_type_offerings.nodes[each.key].locations)) == 0
      error_message = <<-EOM
        Instance type(s) ${jsonencode(each.value.instance_types)} for node group ${format("%q", each.key)} are not available in all the given zones:
        given = ${jsonencode(each.value.availability_zone_ids)}
        available = ${jsonencode(data.aws_ec2_instance_type_offerings.nodes[each.key].locations)}
      EOM
    }
    ignore_changes = [
      block_device_mappings[0].ebs[0].kms_key_id,
    ]
  }
}

data "aws_ssm_parameter" "eks_ami_release_version" {
  name = "/aws/service/eks/optimized-ami/${var.eks_info.cluster.version}/amazon-linux-2/recommended/release_version"
}

data "aws_ssm_parameter" "eks_gpu_ami_release_version" {
  name = "/aws/service/eks/optimized-ami/${var.eks_info.cluster.version}/amazon-linux-2-gpu/recommended/release_version"
}

resource "aws_eks_node_group" "node_groups" {
  for_each             = local.node_groups_by_name
  cluster_name         = var.eks_info.cluster.specs.name
  version              = each.value.node_group.ami != null ? null : var.eks_info.cluster.version
  release_version      = each.value.node_group.ami != null ? null : (each.value.node_group.gpu ? nonsensitive(data.aws_ssm_parameter.eks_gpu_ami_release_version.value) : nonsensitive(data.aws_ssm_parameter.eks_ami_release_version.value))
  node_group_name      = "${var.eks_info.cluster.specs.name}-${each.key}"
  node_role_arn        = var.eks_info.nodes.roles[0].arn
  subnet_ids           = [each.value.subnet.subnet_id]
  force_update_version = true
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

  update_config {
    max_unavailable = 1
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
