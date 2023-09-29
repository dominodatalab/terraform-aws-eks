resource "aws_efs_file_system" "eks" {
  encrypted                       = true
  performance_mode                = "generalPurpose"
  provisioned_throughput_in_mibps = "0"
  throughput_mode                 = "bursting"
  kms_key_id                      = local.kms_key_arn

  tags = merge(local.backup_tagging, {
    "Name" = var.deploy_id
  })

  lifecycle {
    ignore_changes = [
      kms_key_id,
    ]
  }

}

resource "aws_security_group" "efs" {
  name        = "${var.deploy_id}-efs"
  description = "EFS security group"
  vpc_id      = var.network_info.vpc_id

  lifecycle {
    create_before_destroy = true
  }
  tags = {
    "Name" = "${var.deploy_id}-efs"
  }
}

resource "aws_efs_mount_target" "eks" {
  count           = length(local.private_subnet_ids)
  file_system_id  = aws_efs_file_system.eks.id
  security_groups = [aws_security_group.efs.id]
  subnet_id       = element(local.private_subnet_ids, count.index)
}

resource "aws_efs_access_point" "eks" {
  file_system_id = aws_efs_file_system.eks.id

  posix_user {
    gid = "0"
    uid = "0"
  }

  root_directory {
    creation_info {
      owner_gid   = "0"
      owner_uid   = "0"
      permissions = "777"
    }

    path = var.storage.efs.access_point_path
  }
}
