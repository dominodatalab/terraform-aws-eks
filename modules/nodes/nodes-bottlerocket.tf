resource "aws_launch_template" "node_groups_bottlerocket" {
  for_each                = { for name, ng in local.node_groups: name => ng if ng.use_bottlerocket }
  name                    = "${var.eks_info.cluster.specs.name}-${each.key}"
  disable_api_termination = false
  key_name                = var.ssh_key.key_pair_name
  user_data = base64encode(templatefile(
    "${path.module}/templates/bottlerocket_user_data.tpl",
    {
      # https://bottlerocket.dev/en/os/1.39.x/api/settings/kubernetes/#tag-required-eks
      # Required to bootstrap node
      cluster_name        = var.eks_info.cluster.specs.name
      cluster_endpoint    = var.eks_info.cluster.specs.endpoint
      cluster_auth_base64 = var.eks_info.cluster.specs.certificate_authority[0].data
      cluster_dns_ips     = try(cidrhost(var.eks_info.cluster.specs.kubernetes_network_config.service_ipv4_cidr, 10), "")
  }))
  vpc_security_group_ids = [var.eks_info.nodes.security_group_id]
  image_id               = each.value.ami

  dynamic "block_device_mappings" {
    for_each = each.value.block_device_map
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