module "k8s_setup" {
  count = var.bastion_info != null || var.eks.public_access.enabled ? 1 : 0

  source       = "../k8s"
  ssh_key      = var.ssh_key
  bastion_info = var.bastion_info
  network_info = var.network_info
  eks_info     = local.eks_info

  depends_on = [aws_eks_addon.vpc_cni, null_resource.kubeconfig]
}
