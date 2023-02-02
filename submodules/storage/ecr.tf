locals {
  encryption_type = var.ecr_kms_key != null ? "KMS" : "AES256"
}

resource "aws_ecr_repository" "environment" {
  name                 = "${var.deploy_id}/environment"
  image_tag_mutability = "IMMUTABLE"

  encryption_configuration {
    encryption_type = local.encryption_type
    kms_key         = var.ecr_kms_key
  }

  force_delete = var.ecr_force_destroy_on_deletion
}

resource "aws_ecr_repository" "model" {
  name                 = "${var.deploy_id}/model"
  image_tag_mutability = "IMMUTABLE"

  encryption_configuration {
    encryption_type = local.encryption_type
    kms_key         = var.ecr_kms_key
  }

  force_delete = var.ecr_force_destroy_on_deletion
}
