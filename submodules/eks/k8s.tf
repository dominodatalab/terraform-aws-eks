locals {
  run_setup = var.bastion_info != null || var.eks.public_access.enabled ? 1 : 0
}

module "k8s_setup" {
  count = local.run_setup

  source       = "../k8s"
  ssh_key      = var.ssh_key
  bastion_info = var.bastion_info
  network_info = var.network_info
  eks_info     = local.eks_info

  depends_on = [aws_eks_addon.vpc_cni, null_resource.kubeconfig]
}

resource "terraform_data" "run_k8s_pre_setup" {
  count = local.run_setup

  triggers_replace = [
    module.k8s_setup[0].change_hash
  ]

  provisioner "local-exec" {
    command     = "bash ./${module.k8s_setup[0].filename} set_k8s_auth set_eniconfig"
    interpreter = ["bash", "-c"]
    working_dir = module.k8s_setup[0].resources_directory
  }

  depends_on = [module.k8s_setup]
}

resource "terraform_data" "calico_setup" {
  count = local.run_setup

  triggers_replace = [
    module.k8s_setup[0].change_hash
  ]

  provisioner "local-exec" {
    command     = "bash ./${module.k8s_setup[0].filename} install_calico"
    interpreter = ["bash", "-c"]
    working_dir = module.k8s_setup[0].resources_directory
  }

  depends_on = [aws_eks_node_group.node_groups, terraform_data.run_k8s_pre_setup]
}
