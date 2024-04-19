output "info" {
  description = "EKS information"
  value = merge(local.eks_info, {
    k8s_pre_setup_sh_file     = local.k8s_pre_setup_sh_file
    k8s_pre_setup_change_hash = local.k8s_pre_setup_change_hash
    privatelink               = try(module.privatelink[0].info, null)
    }
  )
}
