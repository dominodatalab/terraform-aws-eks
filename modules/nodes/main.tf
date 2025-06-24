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

  node_group_status = {
    for name, ng in merge(var.karpenter_node_groups, var.additional_node_groups, var.default_node_groups) :
    name => {
      is_gpu    = coalesce(ng.gpu, false) || anytrue([for itype in ng.instance_types : length(data.aws_ec2_instance_type.all[itype].gpus) > 0])
      is_neuron = coalesce(try(ng.neuron, false), false) || anytrue([for itype in ng.instance_types : length(try(data.aws_ec2_instance_type.all[itype].neuron_devices, [])) > 0])
    }
  }

  node_group_ami_class_types = {
    for name, ng in merge(var.karpenter_node_groups, var.additional_node_groups, var.default_node_groups) :
    name => {
      ami_class = ng.ami != null ? "custom" : (
        local.node_group_status[name].is_neuron ? "neuron" :
        local.node_group_status[name].is_gpu ? "nvidia" :
        "standard"
      )
    }
  }

  node_groups = {
    for name, ng in merge(var.karpenter_node_groups, var.additional_node_groups, var.default_node_groups) :
    name => merge(ng, {
      is_gpu          = local.node_group_status[name].is_gpu
      is_neuron       = local.node_group_status[name].is_neuron
      ami_type        = local.ami_type_map[local.node_group_ami_class_types[name].ami_class].ami_type
      release_version = try(local.ami_version_mappings[ng.ami_class].release_version, null)
      instance_tags   = merge(data.aws_default_tags.this.tags, ng.tags, local.node_group_status[name].is_neuron ? { "k8s.io/cluster-autoscaler/node-template/resources/aws.amazon.com/neuron" = "1" } : null)
      #Omit the karpenter nodegroups to mitigate daemonsets scheduling issues.
      labels = merge(
        local.node_group_status[name].is_gpu ? local.gpu_labels : {},
        ng.labels,
        lookup(coalesce(var.karpenter_node_groups, {}), name, null) == null ? { "dominodatalab.com/domino-node" = true } : {}
      )
      taints = local.node_group_status[name].is_gpu ? distinct(concat(local.gpu_taints, ng.taints)) : ng.taints
    })
  }

  multi_zone_node_groups = [
    for ng_name, ng in local.node_groups : {
      ng_name            = ng_name
      sb_name            = join("_", [for sb_name, sb in var.network_info.subnets.private : sb.az_id if contains(ng.availability_zone_ids, sb.az_id)])
      sb_az_id           = join("_", [for sb_name, sb in var.network_info.subnets.private : sb.az_id if contains(ng.availability_zone_ids, sb.az_id)])
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
        ng_name  = ng_name
        sb_name  = sb.name
        sb_az_id = sb.az_id
        subnet   = sb
        node_group = merge(ng, {
          availability_zone_ids = [sb.az_id]
          availability_zones    = [sb.az]
        })
      }
      if !lookup(ng, "single_nodegroup", false) && contains(ng.availability_zone_ids, sb.az_id)
    ]
  ])

  node_groups_per_zone = concat(local.multi_zone_node_groups, local.single_zone_node_groups)

  node_groups_by_name_pre = { for ngz in local.node_groups_per_zone : replace(strcontains("${ngz.ng_name}-${ngz.sb_name}", var.eks_info.cluster.specs.name) ? "${ngz.ng_name}-${ngz.sb_name}" : "${ngz.ng_name}-${var.eks_info.cluster.specs.name}-${ngz.sb_name}", " ", "_") => ngz }

  node_groups_by_name = {
    for ng_name, ng in local.node_groups_by_name_pre :
    length(ng_name) <= 63 ? ng_name : (
      length("${ng.ng_name}-${var.eks_info.cluster.specs.name}-${ng.sb_az_id}") <= 63 ?
      "${ng.ng_name}-${var.eks_info.cluster.specs.name}-${ng.sb_az_id}" :
      substr("${ng.ng_name}-${var.eks_info.cluster.specs.name}-${ng.sb_az_id}", 0, 63)
    ) => ng
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

resource "terraform_data" "delete_karpenter_instances" {
  count = var.karpenter_node_groups != null && try(fileexists(var.eks_info.k8s_pre_setup_sh_file), false) ? 1 : 0

  input = {
    k8s_pre_setup_sh_file = basename(var.eks_info.k8s_pre_setup_sh_file)
    working_dir           = dirname(var.eks_info.k8s_pre_setup_sh_file)
  }

  provisioner "local-exec" {
    when        = destroy
    command     = "bash ./${self.input.k8s_pre_setup_sh_file} terminate_karpenter_instances"
    interpreter = ["bash", "-c"]
    working_dir = self.input.working_dir
  }
}

locals {
  karpenter_az_ids        = var.karpenter_node_groups != null ? flatten([for ng in var.karpenter_node_groups : ng.availability_zone_ids]) : []
  karpenter_subnets       = var.karpenter_node_groups != null ? flatten([for ng in var.karpenter_node_groups : [for sb in var.network_info.subnets.private : sb.subnet_id if contains(local.karpenter_az_ids, sb.az_id)]]) : []
  karpenter_tag_resources = var.karpenter_node_groups != null ? flatten([var.eks_info.nodes.security_group_id, local.karpenter_subnets]) : []
}

resource "aws_ec2_tag" "karpenter" {
  count       = length(local.karpenter_tag_resources)
  resource_id = local.karpenter_tag_resources[count.index]
  key         = "karpenter.sh/discovery"
  value       = var.eks_info.cluster.specs.name
}
