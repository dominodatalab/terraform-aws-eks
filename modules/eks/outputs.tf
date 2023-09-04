output "info" {
  description = "EKS information"
  value = merge(local.eks_info, {
    k8s_pre_setup_sh_file = local.k8s_pre_setup_sh_file
    }
  )
}

output "privatelink" {
  count       = var.enabled_private_link ? 1 : 0
  description = "Private Link Info"
  value       = module.privatelink.info
}