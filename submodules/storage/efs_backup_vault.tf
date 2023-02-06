resource "aws_backup_vault" "efs" {
  count = var.create_efs_backup_vault ? 1 : 0
  name  = "${var.deploy_id}-efs"

  force_destroy = var.efs_backup_vault_force_destroy
  kms_key_arn   = var.efs_backup_vault_kms_key
}

resource "aws_backup_plan" "efs" {
  count = var.create_efs_backup_vault ? 1 : 0
  name  = "${var.deploy_id}-efs"
  rule {
    rule_name           = "efs-rule"
    recovery_point_tags = {}
    schedule            = "cron(${var.efs_backup_schedule})"
    start_window        = 60
    target_vault_name   = aws_backup_vault.efs[0].name

    lifecycle {
      cold_storage_after = var.efs_backup_cold_storage_after
      delete_after       = var.efs_backup_delete_after
    }
  }
}

resource "aws_iam_role" "efs_backup_role" {
  count = var.create_efs_backup_vault ? 1 : 0
  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Sid    = ""
        Principal = {
          Service = "backup.amazonaws.com"
        }
      },
    ]
  })
}

resource "aws_backup_selection" "efs" {
  count = var.create_efs_backup_vault ? 1 : 0
  name  = "${var.deploy_id}-efs"

  plan_id      = aws_backup_plan.efs[0].id
  iam_role_arn = aws_iam_role.efs_backup_role[0].arn

  resources = [aws_efs_file_system.eks.arn]
}
