locals {
  encryption_type = var.kms_info.enabled ? "KMS" : "AES256"
  ecr_repos       = toset(["model", "environment"])
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
}
