output "efs_access_point" {
  description = "efs access point"
  value       = aws_efs_access_point.eks
}

output "efs_file_system" {
  description = "efs file system"
  value       = aws_efs_file_system.eks
}

output "s3_buckets" {
  description = "S3 buckets name and arn"
  value = { for k, b in local.s3_buckets : k => {
    "bucket_name" = b.bucket_name,
    "arn"         = b.arn
  } }
}

output "iam_policies" {
  description = "IAM Policy ARNs"
  value       = [aws_iam_policy.s3.arn, aws_iam_policy.ecr.arn]
}

output "efs_security_group" {
  description = "EFS security group id"
  value       = aws_security_group.efs.id
}

output "container_registry" {
  description = "ECR base registry URL"

  # Grab the base AWS account ECR URL and add the deploy_id. Domino will append /environment and /model
  value = join("/", concat(slice(split("/", aws_ecr_repository.environment.repository_url), 0, 1), [var.deploy_id]))
}
