output "eks" {
  description = "External deployments eks info"
  value = {
    operator_role_arn = aws_iam_role.external_deployments_operator.arn
  }
}
