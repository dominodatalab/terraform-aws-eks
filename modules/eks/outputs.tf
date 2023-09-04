output "info" {
  description = "EKS information"
  value = merge(local.eks_info, {
    k8s_pre_setup_sh_file = local.k8s_pre_setup_sh_file
    }
  )
}

output "privatelink" {
  description = "Private Link Info"
  value       = var.enabled_private_link ? module.privatelink.info : null
}