output "info" {
  description = "EKS information"
  value = merge(local.eks_info, {
    k8s_pre_setup_sh_file       = local.k8s_pre_setup_sh_file
    eks_nodes_security_group_id = aws_security_group.eks_nodes.id
    }
  )
}
