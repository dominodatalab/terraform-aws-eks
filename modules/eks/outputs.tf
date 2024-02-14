output "info" {
  description = "EKS information"
  value = merge(local.eks_info, {
    k8s_pre_setup_sh_file = local.k8s_pre_setup_sh_file
    privatelink           = try(module.privatelink[0].info, null)
    }
  )
}

output "flyte" {
  description = "Flyte info"
  value = var.flyte.enabled ? {
    eks = {
      account_id            = local.aws_account_id
      controlplane_role_arn = aws_iam_role.flyte_controlplane[0].arn
      dataplane_role_arn    = aws_iam_role.flyte_dataplane[0].arn
    }
  } : null
}