output "info" {
  description = "EKS information"
  value = merge(local.eks_info, {
    k8s_pre_setup_sh_file = local.k8s_pre_setup_sh_file
    load_balancers        = try(module.load_balancers[0].info, null)
    }
  )
}
