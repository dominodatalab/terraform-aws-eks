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
