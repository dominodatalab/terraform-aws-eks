output "eks" {
  description = "Model deployment eks info"
  value = {
    operator_role_arn = aws_iam_role.model_deployment_operator.arn
  }
}
