output "eks" {
  description = "External deployments eks info"
  value = {
    operator_role_arn             = aws_iam_role.operator.arn
    operator_service_account_name = var.external_deployments.operator_service_account_name
    repository                    = local.repository
    bucket                        = local.bucket
    can_assume_any_external_role  = var.external_deployments.enable_assume_any_external_role
    can_deploy_in_account         = var.external_deployments.enable_in_account_deployments
  }
}
