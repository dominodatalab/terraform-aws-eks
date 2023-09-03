output "info" {
  description = "EKS information"
  value = merge(local.eks_info, {
    k8s_pre_setup_sh_file = local.k8s_pre_setup_sh_file
    }
  )
}

output "privatelink_info" {
  description = "Private Link Info"
  value       = module.privatelink.info
}