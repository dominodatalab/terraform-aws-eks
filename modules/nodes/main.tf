data "aws_default_tags" "this" {}

data "aws_ec2_instance_type" "all" {
  for_each      = toset(flatten([for ng in merge(var.additional_node_groups, var.default_node_groups) : ng.instance_types]))
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
    (var.no_default_ngs ? var.additional_node_groups : merge(var.additional_node_groups, var.default_node_groups)) :
    name => merge(ng, {
      gpu           = coalesce(ng.gpu, false) || anytrue([for itype in ng.instance_types : length(data.aws_ec2_instance_type.all[itype].gpus) > 0])
      instance_tags = merge(data.aws_default_tags.this.tags, ng.tags)
      labels        = coalesce(ng.gpu, false) || anytrue([for itype in ng.instance_types : length(data.aws_ec2_instance_type.all[itype].gpus) > 0]) ? merge(local.gpu_labels, ng.labels) : ng.labels
      taints        = coalesce(ng.gpu, false) || anytrue([for itype in ng.instance_types : length(data.aws_ec2_instance_type.all[itype].gpus) > 0]) ? distinct(concat(local.gpu_taints, ng.taints)) : ng.taints
    })
  }
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

locals {
  node_groups_per_zone = flatten([
    for ng_name, ng in local.node_groups : [
      for sb_name, sb in var.network_info.subnets.private : {
        ng_name    = ng_name
        sb_name    = sb_name
        subnet     = sb
        node_group = ng
      } if contains(ng.availability_zone_ids, sb.az_id)
    ]
  ])
  node_groups_by_name = { for ngz in local.node_groups_per_zone : "${ngz.ng_name}-${ngz.sb_name}" => ngz }
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
