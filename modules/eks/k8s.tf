locals {
  run_setup                 = var.bastion_info != null || var.eks.public_access.enabled ? 1 : 0
  k8s_pre_setup_sh_file     = local.run_setup != 0 ? module.k8s_setup[0].filepath : null
  k8s_pre_setup_change_hash = local.run_setup != 0 ? module.k8s_setup[0].change_hash : null
  # FIPS isn't supported on pull through cache URLs yet
  # GovCloud and China don't support pull through cache
  # https://docs.aws.amazon.com/AmazonECR/latest/userguide/pull-through-cache.html#pull-through-cache-considerations
  supports_pull_through_cache = data.aws_partition.current.partition == "aws" && !var.use_fips_endpoint
}

module "k8s_setup" {
  count = local.run_setup

  source            = "./submodules/k8s"
  ssh_key           = var.ssh_key
  bastion_info      = var.bastion_info
  eks_info          = local.eks_info
  use_fips_endpoint = var.use_fips_endpoint

  # Note: must match modules/infra/submodules/storage/ecr.tf
  calico_image_registry = local.supports_pull_through_cache ? "${data.aws_caller_identity.aws_account.id}.dkr.ecr.${var.region}.amazonaws.com/${var.deploy_id}/quay" : "quay.io"

  depends_on = [null_resource.kubeconfig]
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
