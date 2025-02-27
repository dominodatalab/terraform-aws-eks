data "aws_default_tags" "this" {}

data "aws_ec2_instance_type" "all" {
  for_each      = toset(flatten([for ng in merge(var.karpenter_node_groups, var.additional_node_groups, var.default_node_groups) : ng.instance_types]))
  instance_type = each.value
}

locals {
  gpu_labels = { "nvidia.com/gpu" = true }
  gpu_taints = [{
    key    = "nvidia.com/gpu"
    value  = "true"
    effect = "NO_SCHEDULE"
  }]
  node_groups = {
    for name, ng in
    merge(var.karpenter_node_groups, var.additional_node_groups, var.default_node_groups) :
    name => merge(ng, {
      gpu           = coalesce(ng.gpu, false) || anytrue([for itype in ng.instance_types : length(data.aws_ec2_instance_type.all[itype].gpus) > 0])
      instance_tags = merge(data.aws_default_tags.this.tags, ng.tags)
      labels        = coalesce(ng.gpu, false) || anytrue([for itype in ng.instance_types : length(data.aws_ec2_instance_type.all[itype].gpus) > 0]) ? merge(local.gpu_labels, ng.labels) : ng.labels
      taints        = coalesce(ng.gpu, false) || anytrue([for itype in ng.instance_types : length(data.aws_ec2_instance_type.all[itype].gpus) > 0]) ? distinct(concat(local.gpu_taints, ng.taints)) : ng.taints
    })
  }

  multi_zone_node_groups = [
    for ng_name, ng in local.node_groups : {
      ng_name            = ng_name
      sb_name            = join("_", [for sb_name, sb in var.network_info.subnets.private : sb.az_id if contains(ng.availability_zone_ids, sb.az_id)])
      subnet             = { for sb in var.network_info.subnets.private : sb.name => sb if contains(ng.availability_zone_ids, sb.az_id) }
      availability_zones = [for sb in var.network_info.subnets.private : sb.az if contains(ng.availability_zone_ids, sb.az_id)]
      node_group = merge(ng, {
        availability_zone_ids = [for sb in var.network_info.subnets.private : sb.az_id if contains(ng.availability_zone_ids, sb.az_id)]
        availability_zones    = [for sb in var.network_info.subnets.private : sb.az if contains(ng.availability_zone_ids, sb.az_id)]
      })
    }
    if lookup(ng, "single_nodegroup", false)
  ]

  single_zone_node_groups = flatten([
    for ng_name, ng in local.node_groups : [
      for sb_name, sb in var.network_info.subnets.private : {
        ng_name = ng_name
        sb_name = sb.name
        subnet  = sb
        node_group = merge(ng, {
          availability_zone_ids = [sb.az_id]
          availability_zones    = [sb.az]
        })
      }
      if !lookup(ng, "single_nodegroup", false) && contains(ng.availability_zone_ids, sb.az_id)
    ]
  ])

  node_groups_per_zone = concat(local.multi_zone_node_groups, local.single_zone_node_groups)

  node_groups_by_name = { for ngz in local.node_groups_per_zone : "${ngz.ng_name}-${ngz.sb_name}" => ngz }
}

data "aws_ec2_instance_type_offerings" "nodes" {
  for_each = {
    for name, ng in local.node_groups :
    name => ng.instance_types
  }

  filter {
    name   = "instance-type"
    values = each.value
  }

  location_type = "availability-zone-id"
}

data "aws_ami" "custom" {
  for_each = toset([for k, v in local.node_groups : v.ami if v.ami != null])

  filter {
    name   = "image-id"
    values = [each.value]
  }
}

resource "terraform_data" "calico_setup" {
  count = try(fileexists(var.eks_info.k8s_pre_setup_sh_file), false) ? 1 : 0

  triggers_replace = [
    filemd5(var.eks_info.k8s_pre_setup_sh_file)
  ]

  provisioner "local-exec" {
    command     = "bash ./${basename(var.eks_info.k8s_pre_setup_sh_file)} install_calico"
    interpreter = ["bash", "-c"]
    working_dir = dirname(var.eks_info.k8s_pre_setup_sh_file)
  }

  depends_on = [aws_eks_node_group.node_groups]
}

resource "terraform_data" "karpenter_setup" {
  count = var.karpenter_node_groups != null && try(fileexists(var.eks_info.k8s_pre_setup_sh_file), false) ? 1 : 0

  triggers_replace = [
    filemd5(var.eks_info.k8s_pre_setup_sh_file)
  ]

  provisioner "local-exec" {
    command     = "bash ./${basename(var.eks_info.k8s_pre_setup_sh_file)} install_karpenter"
    interpreter = ["bash", "-c"]
    working_dir = dirname(var.eks_info.k8s_pre_setup_sh_file)
  }

  depends_on = [terraform_data.calico_setup]
}

locals {
  karpenter_tag_resources = var.karpenter_node_groups != null ? flatten([var.eks_info.nodes.security_group_id, [for sb in var.network_info.subnets.private : sb.subnet_id]]) : []
}

resource "aws_ec2_tag" "karpenter" {
  count       = length(local.karpenter_tag_resources)
  resource_id = local.karpenter_tag_resources[count.index]
  key         = "karpenter.sh/discovery"
  value       = var.eks_info.cluster.specs.name
}
