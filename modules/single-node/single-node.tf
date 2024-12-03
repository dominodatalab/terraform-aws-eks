locals {
  node_labels = merge({
    "node-type"   = "single-node"
    "single-node" = "true"
  }, var.single_node.labels)
  instance_labels = merge({
    "kubernetes.io/cluster/${var.eks_info.cluster.specs.name}" = "owned"
    "k8s.io/cluster/${var.eks_info.cluster.specs.name}"        = "owned"
    "Name"                                                     = "${var.eks_info.cluster.specs.name}-${var.single_node.name}"
    # iam-bootstrap uses "ec2:ResourceTag/cluster" for ec2 perms
    "cluster" = var.eks_info.cluster.specs.name
  }, data.aws_default_tags.this.tags, local.node_labels)

  kubelet_extra_args = "--kubelet-extra-args '--node-labels=${join(",", [for k, v in local.node_labels : format("%s=%s", k, v)])}'"

  bootstrap_extra_args = join(" ", [local.kubelet_extra_args, var.single_node.bootstrap_extra_args])
}

resource "aws_security_group" "single_node" {
  name                   = "${var.eks_info.cluster.specs.name}-${var.single_node.name}"
  description            = "Single Node security group"
  revoke_rules_on_delete = true
  vpc_id                 = var.network_info.vpc_id

  lifecycle {
    create_before_destroy = true
    ignore_changes        = [description]
  }

  tags = {
    "Name" = "${var.eks_info.cluster.specs.name}-${var.single_node.name}"
  }

}

resource "aws_security_group_rule" "single_node" {
  for_each = local.security_group_rules

  security_group_id = aws_security_group.single_node.id
  protocol          = each.value.protocol
  from_port         = each.value.from_port
  to_port           = each.value.to_port
  type              = each.value.type
  description       = each.value.description
  cidr_blocks       = each.value.cidr_blocks
}

resource "aws_launch_template" "single_node" {
  name                    = "${var.eks_info.cluster.specs.name}-${var.single_node.name}"
  disable_api_termination = false
  key_name                = var.ssh_key.key_pair_name
  update_default_version  = true
  user_data = base64encode(templatefile(
    "${path.module}/templates/linux_user_data.tpl",
    {
      cluster_name        = var.eks_info.cluster.specs.name
      cluster_endpoint    = var.eks_info.cluster.specs.endpoint
      cluster_auth_base64 = var.eks_info.cluster.specs.certificate_authority[0].data
      # Optional
      cluster_service_ipv4_cidr = var.eks_info.cluster.specs.kubernetes_network_config.service_ipv4_cidr != null ? var.eks_info.cluster.specs.kubernetes_network_config.service_ipv4_cidr : ""
      bootstrap_extra_args      = local.bootstrap_extra_args
      pre_bootstrap_user_data   = ""
      post_bootstrap_user_data  = ""
  }))

  vpc_security_group_ids = [var.eks_info.nodes.security_group_id, aws_security_group.single_node.id]
  image_id               = data.aws_ami.single_node.id

  block_device_mappings {
    device_name = try(data.aws_ami.single_node.root_device_name, "/dev/xvda")

    ebs {
      delete_on_termination = true
      encrypted             = true
      volume_size           = var.single_node.volume.size
      volume_type           = var.single_node.volume.type
      kms_key_id            = var.kms_info.enabled ? var.kms_info.key_arn : null
    }
  }

  metadata_options {
    http_endpoint               = "enabled"
    http_put_response_hop_limit = "2"
    http_tokens                 = "required"
  }

  dynamic "tag_specifications" {
    for_each = toset(["instance", "volume"])
    content {
      resource_type = tag_specifications.value
      tags          = local.instance_labels
    }
  }

  lifecycle {
    ignore_changes = [
      block_device_mappings[0].ebs[0].kms_key_id,
    ]
  }
}


resource "aws_iam_instance_profile" "single_node" {
  name = "${var.eks_info.cluster.specs.name}-${var.single_node.name}"
  role = var.eks_info.nodes.roles[0].name
}


resource "aws_instance" "single_node" {
  subnet_id            = var.network_info.subnets.public[0].subnet_id
  iam_instance_profile = aws_iam_instance_profile.single_node.name
  instance_type        = var.single_node.instance_type
  monitoring           = true

  launch_template {
    id      = aws_launch_template.single_node.id
    version = "$Latest"
  }
  root_block_device {
    delete_on_termination = true
    encrypted             = true
    iops                  = "3000"
  }

  metadata_options {
    http_endpoint          = "enabled"
    http_tokens            = "required"
    instance_metadata_tags = "disabled"
  }

  tags = local.instance_labels
}


resource "aws_eip" "single_node" {
  instance             = aws_instance.single_node.id
  network_border_group = var.region
  domain               = "vpc"
}

resource "aws_eip_association" "single_node" {
  network_interface_id = aws_instance.single_node.primary_network_interface_id
  allocation_id        = aws_eip.single_node.id
}
