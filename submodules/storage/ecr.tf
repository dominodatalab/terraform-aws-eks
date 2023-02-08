locals {
  encryption_type = var.ecr_kms_key != null ? "KMS" : "AES256"
  ecr_repos       = toset(["model", "environment"])
}

resource "aws_ecr_repository" "this" {
  for_each             = local.ecr_repos
  name                 = join("/", [var.deploy_id, each.key])
  image_tag_mutability = "IMMUTABLE"

  encryption_configuration {
    encryption_type = local.encryption_type
    kms_key         = var.ecr_kms_key
  }

  force_delete = var.ecr_force_destroy_on_deletion
}
