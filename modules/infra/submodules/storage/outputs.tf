output "info" {
  description = <<EOF
    efs = {
      access_point      = EFS access point.
      file_system       = EFS file_system.
      security_group_id = EFS security group id.
    }
    s3 = {
      buckets        = "S3 buckets name and arn"
      iam_policy_arn = S3 IAM Policy ARN.
    }
    ecr = {
      container_registry = ECR base registry URL. Grab the base AWS account ECR URL and add the deploy_id. Domino will append /environment and /model.
      iam_policy_arn     = ECR IAM Policy ARN.
    }
  EOF
  value = {
    efs = {
      access_point      = aws_efs_access_point.eks
      file_system       = aws_efs_file_system.eks
      security_group_id = aws_security_group.efs.id
    }
    s3 = {
      buckets = { for k, b in local.s3_buckets : k => {
        "bucket_name" = b.bucket_name,
        "arn"         = b.arn
      } }
      iam_policy_arn = aws_iam_policy.s3.arn
    }
    ecr = {
      container_registry = join("/", concat(slice(split("/", aws_ecr_repository.this["environment"].repository_url), 0, 1), [var.deploy_id]))
      iam_policy_arn     = aws_iam_policy.ecr.arn
    }
  }
}
