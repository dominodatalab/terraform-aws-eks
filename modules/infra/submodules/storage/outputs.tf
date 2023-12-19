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
    rds = {
      address = "Hostname of RDS Postgres instance"
      port = "Port of RDS postgres instance"
      username = "Master username for RDS postgres instance
      master_user_secret = "Secret information for RDS postgres instance"
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
    rds = {
      address = var.storage.rds.enabled ? aws_db_instance.postgresql[0].address: null
      port = var.storage.rds.enabled ? aws_db_instance.postgresql[0].port : null
      username = var.storage.rds.enabled ? aws_db_instance.postgresql[0].username : null
      master_user_secret = var.storage.rds.enabled ? aws_db_instance.postgresql[0].master_user_secret : null
      security_group_id = var.storage.rds.enabled ? aws_security_group.postgresql[0].id : null
    }
  }
}
