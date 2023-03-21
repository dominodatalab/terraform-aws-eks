data "aws_iam_role" "eks_master_roles" {
  for_each = toset(var.eks.master_role_names)
  name     = each.key
}

module "k8s_setup" {
  count = var.bastion_info != null || var.eks.public_access.enabled ? 1 : 0

  source          = "../k8s"
  ssh_key         = var.ssh_key
  bastion_info    = var.bastion_info
  kubeconfig_path = local.kubeconfig_path

  security_group_id    = aws_security_group.eks_nodes.id
  eks_custom_role_maps = var.eks.custom_role_maps
  eks_cluster_arn      = aws_eks_cluster.this.arn
  eks_node_role_arns   = [aws_iam_role.eks_nodes.arn]
  eks_master_role_arns = [for r in concat(values(data.aws_iam_role.eks_master_roles), [aws_iam_role.eks_cluster]) : r.arn]
  network_info         = var.network_info


  # ssh_pvt_key_path     = var.ssh_key.path
  # pod_subnets       = var.network_info.subnets.pod
  # bastion_user      = var.bastion_info.user
  # bastion_public_ip = var.bastion_info.public_ip

  depends_on = [aws_eks_addon.vpc_cni, null_resource.kubeconfig]
}
