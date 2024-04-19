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
      calico_image_registry = Image registry for Calico. Will be a pull through cache for Quay.io unless in GovCloud, China, or have FIPS enabled. 
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
        "bucket_name"               = b.bucket_name,
        "arn"                       = b.arn
        "domain_name"               = b.domain_name
        "regional_domain_name"      = b.regional_domain_name
        "fips_regional_domain_name" = b.fips_regional_domain_name
        }
      }
      iam_policy_arn = aws_iam_policy.s3.arn
    }
    ecr = {
      container_registry    = join("/", concat(slice(split("/", aws_ecr_repository.this["environment"].repository_url), 0, 1), [var.deploy_id]))
      iam_policy_arn        = aws_iam_policy.ecr.arn
      calico_image_registry = local.supports_pull_through_cache ? "${data.aws_caller_identity.this.id}.dkr.ecr.${var.region}.amazonaws.com/${var.deploy_id}/quay" : "quay.io"
    }
  }
}
