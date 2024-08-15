output "eks" {
  description = "External deployments eks info"
  value = {
    operator = {
      role_arn             = aws_iam_role.operator
      service_account_name = var.serviceaccount_names.operator
    }
  }
}
