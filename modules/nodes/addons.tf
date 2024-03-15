removed {
  from = aws_eks_addon.this
  lifecycle {
    destroy = false
  }
}

moved {
  from = aws_eks_addon.this["coredns"]
  to   = aws_eks_addon.post_compute_addons["coredns"]
}

moved {
  from = aws_eks_addon.this["aws-ebs-csi-driver"]
  to   = aws_eks_addon.post_compute_addons["aws-ebs-csi-driver"]
}

moved {
  from = aws_eks_addon.this["kube-proxy"]
  to   = aws_eks_addon.pre_compute_addons["kube-proxy"]
}

data "aws_eks_addon_version" "default" {
  for_each           = toset(var.eks_info.cluster.addons)
  addon_name         = each.key
  kubernetes_version = var.eks_info.cluster.version
}

locals {
  post_compute_addons = setintersection(var.eks_info.cluster.addons, ["coredns", "aws-ebs-csi-driver"])
  pre_compute_addons  = setsubtract(var.eks_info.cluster.addons, local.post_compute_addons)

  is_pod_sb = length(var.network_info.subnets.pod) > 0

  vpc_cni_env = merge({
    ENABLE_PREFIX_DELEGATION = tostring(try(var.eks_info.cluster.vpc_cni.prefix_delegation, false))
    ANNOTATE_POD_IP          = tostring(try(var.eks_info.cluster.vpc_cni.annotate_pod_ip, true))
    }, local.is_pod_sb ? {
    AWS_VPC_K8S_CNI_CUSTOM_NETWORK_CFG = "true"
  ENI_CONFIG_LABEL_DEF = "topology.kubernetes.io/zone" } : {})

  vpc_cni_eni_config = {
    create = true
    region = var.region
    subnets = {
      for sb in var.network_info.subnets.pod : sb.az => {
        id             = sb.subnet_id
        securityGroups = [var.eks_info.nodes.security_group_id]
      }
    }
  }

  vpc_cni_configuration_values = merge({ env = local.vpc_cni_env }, local.is_pod_sb ? { eniConfig = local.vpc_cni_eni_config } : {})

  addons_config_values = {
    vpc-cni = local.vpc_cni_configuration_values
  }

  addons_config_values_json = { for k, v in local.addons_config_values : k => jsonencode(v) }
}

resource "aws_eks_addon" "pre_compute_addons" {
  for_each                    = local.pre_compute_addons
  cluster_name                = var.eks_info.cluster.specs.name
  addon_name                  = each.key
  addon_version               = data.aws_eks_addon_version.default[each.key].version
  resolve_conflicts_on_create = "OVERWRITE"
  resolve_conflicts_on_update = "OVERWRITE"
  configuration_values        = lookup(local.addons_config_values_json, each.key, null)
}


resource "aws_eks_addon" "post_compute_addons" {
  for_each                    = local.post_compute_addons
  cluster_name                = var.eks_info.cluster.specs.name
  addon_name                  = each.key
  addon_version               = data.aws_eks_addon_version.default[each.key].version
  resolve_conflicts_on_create = "OVERWRITE"
  resolve_conflicts_on_update = "OVERWRITE"
  configuration_values        = lookup(local.addons_config_values_json, each.key, null)
  depends_on                  = [aws_eks_node_group.node_groups]
}
