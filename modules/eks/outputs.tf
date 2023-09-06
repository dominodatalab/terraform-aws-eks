output "info" {
  description = "EKS information"
  value = merge(local.eks_info, {
    k8s_pre_setup_sh_file = local.k8s_pre_setup_sh_file
    }
  )
}

output "privatelink" {
  description = "Private Link Info"
  value       = var.enable_private_link ? module.privatelink[0].info : null
}