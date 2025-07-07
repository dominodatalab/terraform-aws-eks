resource "aws_launch_template" "node_groups_bottlerocket" {
  for_each                = { for k,v in local.node_groups: k => v if k[v].use_bottlerocket == true }
  name                    = "${var.eks_info.cluster.specs.name}-${each.key}"
  disable_api_termination = false
  key_name                = var.ssh_key.key_pair_name
  user_data               = base64encode(templatefile(
    "${path.module}/templates/bottlerocket_user_data.tpl",
    {
      # https://bottlerocket.dev/en/os/1.39.x/api/settings/kubernetes/#tag-required-eks
      # Required to bootstrap node
      cluster_name        = var.eks_info.cluster.specs.name
      cluster_endpoint    = var.eks_info.cluster.specs.endpoint
      cluster_auth_base64 = var.eks_info.cluster.specs.certificate_authority[0].data
  }))
  vpc_security_group_ids = [var.eks_info.nodes.security_group_id]
  image_id               = data.aws_ssm_parameter.bottlerocket_ami[each.value.ami_type].value

  dynamic "block_device_mappings" {
      for_each = each.value[block_device_map]
    content {
      device_name = block_device_mappings.value.device_name
      ebs {
        delete_on_termination = block_device_mappings.value.delete_on_termination
        encrypted             = block_device_mappings.value.encrypted
        volume_size           = block_device_mappings.value.volume_size
        volume_type           = block_device_mappings.value.volume_type
        iops                  = block_device_mappings.value.iops
        throughput            = block_device_mappings.value.throughput
        kms_key_id            = block_device_mappings.value.kms_key_id
      }
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
      condition     = (lookup(each.value, "single_nodegroup", false) && length(setintersection(each.value.availability_zone_ids, data.aws_ec2_instance_type_offerings.nodes[each.key].locations)) > 0) || length(setsubtract(each.value.availability_zone_ids, data.aws_ec2_instance_type_offerings.nodes[each.key].locations)) == 0
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

data "aws_ssm_parameter" "bottlerocket_ami" {
  for_each = { for k, v in local.ami_type_map : k => v if v.ami_type == "BOTTLEROCKET" }
  name     = "/aws/service/bottlerocket/aws-k8s-${var.eks_info.cluster.version}%{if each.value.ssm_ami_param != null}-${each.value.ssm_ami_param}%{endif}/x86_64/latest/image_id"
}


resource "aws_eks_node_group" "node_groups" {
  for_each             = local.node_groups_by_name
  cluster_name         = var.eks_info.cluster.specs.name
  version              = each.value.node_group.ami != null ? null : var.eks_info.cluster.version
  release_version      = each.value.node_group.release_version
  node_group_name      = each.key
  node_role_arn        = var.eks_info.nodes.roles[0].arn
  subnet_ids           = try(lookup(each.value.node_group, "single_nodegroup", false), false) ? [for s in values(each.value.subnet) : s.subnet_id] : [each.value.subnet.subnet_id]
  force_update_version = true
  scaling_config {
    min_size     = each.value.node_group.min_per_az
    max_size     = each.value.node_group.max_per_az
    desired_size = each.value.node_group.desired_per_az
  }

  ami_type       = each.value.node_group.ami_type
  capacity_type  = each.value.node_group.spot ? "SPOT" : "ON_DEMAND"
  instance_types = each.value.node_group.instance_types
  launch_template {
    id      = aws_launch_template.node_groups[each.value.ng_name].id
    version = aws_launch_template.node_groups[each.value.ng_name].latest_version
  }

  labels = each.value.node_group.labels

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
    precondition {
      condition     = length(keys(local.node_groups_by_name)) == length(toset(keys(local.node_groups_by_name)))
      error_message = <<-EOM
        Duplicate node group names detected after applying naming logic. This indicates that the name generation logic failed to create unique names.
        Generated names: ${jsonencode(sort(keys(local.node_groups_by_name)))}
        Please check your node group configuration and subnet naming.
      EOM
    }
    ignore_changes = [
      scaling_config[0].desired_size,
      scaling_config[0].min_size,
    ]
  }

  update_config {
    max_unavailable_percentage = each.value.node_group.max_unavailable_percentage
    max_unavailable            = each.value.node_group.max_unavailable
  }

  depends_on = [aws_eks_addon.pre_compute_addons, terraform_data.delete_karpenter_instances]

}

locals {

  asg_tags = flatten([for name, v in local.node_groups_by_name : [
    {
      name  = name
      key   = "k8s.io/cluster-autoscaler/node-template/label/topology.ebs.csi.aws.com/zone"
      value = join(",", v.node_group.availability_zones)
    },
    {
      name  = name
      key   = "k8s.io/cluster-autoscaler/node-template/resources/smarter-devices/fuse"
      value = "20"
    },
    # this is necessary until cluster-autoscaler v1.24, labels and taints are from the nodegroup
    # https://github.com/kubernetes/autoscaler/commit/b4cadfb4e25b6660c41dbe2b73e66e9a2f3a2cc9
    [for lkey, lvalue in v.node_group.labels : {
      name  = name
      key   = format("k8s.io/cluster-autoscaler/node-template/label/%v", lkey)
      value = lvalue
    }],
    [for tkey, tvalue in v.node_group.instance_tags : {
      name  = name
      key   = tkey
      value = tvalue
    }],
    [for t in v.node_group.taints : {
      name  = name
      key   = format("k8s.io/cluster-autoscaler/node-template/taint/%v", t.key)
      value = "${t.value == null ? "" : t.value}:${local.taint_effect_map[t.effect]}"
    }]
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
