output "operator_role_arn" {
  description = "Operator IAM Role ARN"
  value       = aws_iam_role.operator
}

output "operator_service_account_name" {
  description = "Operator Service Account Name"
  value       = var.operator_service_account_name
}

output "repository" {
  description = "ECR Repository for external deployment images"
  value       = local.repository
}

output "bucket" {
  description = "S3 Bucket for external deployment model artifacts"
  value       = local.bucket
}

output "can_assume_any_external_role" {
  description = "Indicates whether policies have been created for the operator role to assume any role to deploy in any other AWS account"
  value       = var.enable_assume_any_external_role
}

output "can_deploy_in_account" {
  description = "Indicates whether policies for the operator role to deploy in this AWS account have been created"
  value       = var.enable_in_account_deployments
}
