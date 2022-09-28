
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

locals {
  gpu_bootstrap_extra_args = ""
  gpu_user_data = base64encode(templatefile("${path.module}/templates/linux_custom.tpl", {
    cluster_name             = aws_eks_cluster.this.name
    cluster_endpoint         = aws_eks_cluster.this.endpoint
    cluster_auth_base64      = aws_eks_cluster.this.certificate_authority[0].data
    bootstrap_extra_args     = local.gpu_bootstrap_extra_args
    pre_bootstrap_user_data  = ""
    post_bootstrap_user_data = "echo ALL DONE !!!"
  }))
  node_group_gpu_ami_id = var.default_node_groups.gpu.ami != null ? var.default_node_groups.gpu.ami : data.aws_ami.eks_gpu.image_id
}


resource "aws_security_group" "eks_nodes" {
  name        = "${local.eks_cluster_name}-nodes"
  description = "EKS cluster Nodes security group"
  vpc_id      = var.vpc_id

  lifecycle {
    create_before_destroy = true
  }
  tags = {
    "Name" = "${local.eks_cluster_name}-eks-nodes"
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

data "aws_ami" "eks_gpu" {
  filter {
    name   = "name"
    values = ["amazon-eks-gpu-node-${var.k8s_version}-v*"]
  }
  most_recent = true
  owners      = ["amazon"]
}

resource "aws_launch_template" "compute" {
  name                    = "${local.eks_cluster_name}-compute"
  disable_api_termination = false
  instance_type           = var.default_node_groups.compute.instance_type
  key_name                = var.ssh_pvt_key_path
  vpc_security_group_ids  = [aws_security_group.eks_nodes.id]
  image_id                = var.default_node_groups.compute.ami

  block_device_mappings {
    device_name = "/dev/xvda"

    ebs {
      delete_on_termination = true
      encrypted             = true
      volume_size           = var.default_node_groups.compute.volume.size
      volume_type           = var.default_node_groups.compute.volume.type
    }
  }

  metadata_options {
    http_endpoint               = "enabled"
    http_put_response_hop_limit = "2"
    http_tokens                 = "required"
  }
  tag_specifications {
    resource_type = "instance"
    tags = {
      "Name" = "${local.eks_cluster_name}-compute"
    }
  }

  tag_specifications {
    resource_type = "volume"
    tags = {
      "Name" = "${local.eks_cluster_name}-compute"
    }
  }
}

resource "aws_eks_node_group" "compute" {
  for_each        = var.private_subnets
  cluster_name    = aws_eks_cluster.this.name
  node_group_name = "${local.eks_cluster_name}-compute-${each.value.availability_zone}"
  node_role_arn   = aws_iam_role.eks_nodes.arn
  subnet_ids      = [each.value.id]
  scaling_config {
    min_size     = var.default_node_groups.compute.min_per_az
    max_size     = var.default_node_groups.compute.max_per_az
    desired_size = var.default_node_groups.compute.desired_per_az
  }

  launch_template {
    id      = aws_launch_template.compute.id
    version = aws_launch_template.compute.latest_version
  }


  labels = {
    "lifecycle"                     = "OnDemand"
    "dominodatalab.com/node-pool"   = "default"
    "dominodatalab.com/domino-node" = true
  }

  lifecycle {
    create_before_destroy = true
    ignore_changes = [
      scaling_config[0].desired_size,
    ]
  }

  depends_on = [
    aws_iam_role_policy_attachment.aws_eks_nodes,
    aws_iam_role_policy_attachment.custom_eks_nodes
  ]
}

resource "aws_launch_template" "platform" {
  name                    = "${local.eks_cluster_name}-platform"
  disable_api_termination = false
  instance_type           = var.default_node_groups.platform.instance_type
  key_name                = var.ssh_pvt_key_path
  vpc_security_group_ids  = [aws_security_group.eks_nodes.id]
  image_id                = var.default_node_groups.platform.ami

  block_device_mappings {
    device_name = "/dev/xvda"

    ebs {
      delete_on_termination = true
      encrypted             = true
      volume_size           = var.default_node_groups.platform.volume.size
      volume_type           = var.default_node_groups.platform.volume.type
    }
  }

  metadata_options {
    http_endpoint               = "enabled"
    http_put_response_hop_limit = "2"
    http_tokens                 = "required"
  }
  tag_specifications {
    resource_type = "instance"
    tags = {
      "Name" = "${local.eks_cluster_name}-platform"
    }
  }

  tag_specifications {
    resource_type = "volume"
    tags = {
      "Name" = "${local.eks_cluster_name}-platform"
    }
  }
}

resource "aws_eks_node_group" "platform" {
  for_each        = var.private_subnets
  cluster_name    = aws_eks_cluster.this.name
  node_group_name = "${local.eks_cluster_name}-platform-${each.value.availability_zone}"
  node_role_arn   = aws_iam_role.eks_nodes.arn
  subnet_ids      = [each.value.id]
  scaling_config {
    min_size     = var.default_node_groups.platform.min_per_az
    max_size     = var.default_node_groups.platform.max_per_az
    desired_size = var.default_node_groups.platform.desired_per_az
  }

  launch_template {
    id      = aws_launch_template.platform.id
    version = aws_launch_template.platform.latest_version
  }


  labels = {
    "lifecycle"                     = "OnDemand"
    "dominodatalab.com/node-pool"   = "platform"
    "dominodatalab.com/domino-node" = true
  }

  lifecycle {
    create_before_destroy = true
    ignore_changes = [
      scaling_config[0].desired_size,
    ]
  }

  depends_on = [
    aws_iam_role_policy_attachment.aws_eks_nodes,
    aws_iam_role_policy_attachment.custom_eks_nodes
  ]
}

resource "aws_launch_template" "gpu" {
  name                    = "${local.eks_cluster_name}-gpu"
  image_id                = local.node_group_gpu_ami_id
  disable_api_termination = false
  instance_type           = var.default_node_groups.gpu.instance_type
  key_name                = var.ssh_pvt_key_path
  vpc_security_group_ids  = [aws_security_group.eks_nodes.id]
  user_data               = local.gpu_user_data
  block_device_mappings {
    device_name = "/dev/xvda"

    ebs {
      delete_on_termination = true
      encrypted             = true
      volume_size           = var.default_node_groups.gpu.volume.size
      volume_type           = var.default_node_groups.gpu.volume.type
    }
  }

  metadata_options {
    http_endpoint               = "enabled"
    http_put_response_hop_limit = "2"
    http_tokens                 = "required"
  }
  tag_specifications {
    resource_type = "instance"
    tags = {
      "Name" = "${local.eks_cluster_name}-gpu"
    }
  }

  tag_specifications {
    resource_type = "volume"
    tags = {
      "Name" = "${local.eks_cluster_name}-gpu"
    }
  }
}

resource "aws_eks_node_group" "gpu" {
  for_each        = var.private_subnets
  cluster_name    = aws_eks_cluster.this.name
  node_group_name = "${local.eks_cluster_name}-gpu-${each.value.availability_zone}"
  node_role_arn   = aws_iam_role.eks_nodes.arn
  subnet_ids      = [each.value.id]
  scaling_config {
    min_size     = var.default_node_groups.gpu.min_per_az
    max_size     = var.default_node_groups.gpu.max_per_az
    desired_size = var.default_node_groups.gpu.desired_per_az
  }

  launch_template {
    id      = aws_launch_template.gpu.id
    version = aws_launch_template.gpu.latest_version
  }

  taint {
    key    = "nvidia.com/gpu"
    value  = true
    effect = "NO_SCHEDULE"
  }
  labels = {
    "lifecycle"                     = "OnDemand"
    "dominodatalab.com/node-pool"   = "default-gpu"
    "dominodatalab.com/domino-node" = true
    "nvidia.com/gpu"                = true
  }

  lifecycle {
    create_before_destroy = true
    ignore_changes = [
      scaling_config[0].desired_size,
    ]
  }

  depends_on = [
    aws_iam_role_policy_attachment.aws_eks_nodes,
    aws_iam_role_policy_attachment.custom_eks_nodes
  ]
}

## Additional node groups

locals {
  additional_node_groups_per_zone = length(var.additional_node_groups) > 0 ? flatten([
    for sb in var.private_subnets : [
      for ng in var.additional_node_groups : {
        # ng_resource_id = "${ng.name}-${sb.zone}"
        subnet     = sb
        node_group = ng
      }
    ]
  ]) : []
}


resource "aws_launch_template" "additional_node_groups" {
  for_each                = var.additional_node_groups
  name                    = "${local.eks_cluster_name}-${try(each.value.name, each.key)}"
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
  tag_specifications {
    resource_type = "instance"
    tags = {
      "Name" = "${local.eks_cluster_name}-${try(each.value.name, each.key)}"
    }
  }

  tag_specifications {
    resource_type = "volume"
    tags = {
      "Name" = "${local.eks_cluster_name}-${try(each.value.name, each.key)}"
    }
  }
}

resource "aws_eks_node_group" "additional_node_groups" {
  for_each        = { for ng in local.additional_node_groups_per_zone : "${ng.node_group.name}-${ng.subnet.availability_zone}" => ng }
  cluster_name    = aws_eks_cluster.this.name
  node_group_name = "${local.eks_cluster_name}-platform-${each.value.subnet.availability_zone}"
  node_role_arn   = aws_iam_role.eks_nodes.arn
  subnet_ids      = [each.value.subnet.id]
  scaling_config {
    min_size     = each.value.node_group.min_per_az
    max_size     = each.value.node_group.max_per_az
    desired_size = each.value.node_group.desired_per_az
  }

  launch_template {
    id      = aws_launch_template.additional_node_groups[each.value.node_group.name].id
    version = aws_launch_template.additional_node_groups[each.value.node_group.name].latest_version
  }


  labels = {
    "lifecycle"                     = "OnDemand"
    "dominodatalab.com/node-pool"   = each.value.node_group.label
    "dominodatalab.com/domino-node" = true
  }

  lifecycle {
    create_before_destroy = true
    ignore_changes = [
      scaling_config[0].desired_size,
    ]
  }

  depends_on = [
    aws_iam_role_policy_attachment.aws_eks_nodes,
    aws_iam_role_policy_attachment.custom_eks_nodes
  ]
}
