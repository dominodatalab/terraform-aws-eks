locals {
  run_setup             = (var.eks.run_k8s_setup || var.bastion_info != null || var.eks.public_access.enabled) ? 1 : 0
  k8s_pre_setup_sh_file = local.run_setup != 0 ? module.k8s_setup[0].filepath : null
}

module "k8s_setup" {
  count = local.run_setup

  source            = "./submodules/k8s"
  ssh_key           = var.ssh_key
  bastion_info      = var.bastion_info
  eks_info          = local.eks_info
  use_fips_endpoint = var.use_fips_endpoint
  cluster_name      = var.deploy_id
  karpenter         = var.karpenter
  region            = var.region
  depends_on        = [null_resource.kubeconfig]
}

resource "terraform_data" "run_k8s_pre_setup" {
  count = local.run_setup

  triggers_replace = [
    module.k8s_setup[0].change_hash
  ]

  provisioner "local-exec" {
    command     = "bash ./${basename(module.k8s_setup[0].filepath)} set_k8s_auth"
    interpreter = ["bash", "-c"]
    working_dir = dirname(module.k8s_setup[0].filepath)
  }

  depends_on = [module.k8s_setup]
}
