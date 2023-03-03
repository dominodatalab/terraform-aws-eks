data "aws_iam_role" "eks_master_roles" {
  for_each = toset(var.eks_master_role_names)
  name     = each.key
}

module "k8s_setup" {
  source               = "../k8s"
  ssh_pvt_key_path     = var.ssh_pvt_key_path
  bastion_user         = var.bastion_user
  bastion_public_ip    = var.bastion_public_ip
  eks_cluster_arn      = aws_eks_cluster.this.arn
  eks_node_role_arns   = [aws_iam_role.eks_nodes.arn]
  eks_master_role_arns = [for r in concat(values(data.aws_iam_role.eks_master_roles), [aws_iam_role.eks_cluster]) : r.arn]
  kubeconfig_path      = var.kubeconfig_path
  eks_custom_role_maps = var.eks_custom_role_maps

  security_group_id = aws_security_group.eks_nodes.id
  pod_subnets       = var.pod_subnets

  depends_on = [aws_eks_addon.vpc_cni, null_resource.kubeconfig]
}
