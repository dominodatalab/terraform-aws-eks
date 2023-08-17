output "role_arn" {
  description = "ARN of bootstrap role"
  value       = aws_iam_role.deployment.arn
}
