locals {
  encryption_type             = var.kms_info.enabled ? "KMS" : "AES256"
  ecr_repos                   = toset(["model", "environment"])
  supports_pull_through_cache = data.aws_partition.current.partition == "aws" && !var.use_fips_endpoint
}

resource "aws_ecr_repository" "this" {
  for_each             = local.ecr_repos
  name                 = join("/", [var.deploy_id, each.key])
  image_tag_mutability = "IMMUTABLE"

  encryption_configuration {
    encryption_type = local.encryption_type
    kms_key         = local.kms_key_arn
  }

  force_delete = var.storage.ecr.force_destroy_on_deletion

  lifecycle {
    ignore_changes = [
      encryption_configuration,
    ]
  }
}

resource "aws_ecr_pull_through_cache_rule" "quay" {
  count                 = local.supports_pull_through_cache ? 1 : 0
  ecr_repository_prefix = "${var.deploy_id}/quay"
  upstream_registry_url = "quay.io"
}
