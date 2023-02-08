resource "aws_efs_file_system" "eks" {
  encrypted                       = true
  performance_mode                = "generalPurpose"
  provisioned_throughput_in_mibps = "0"
  throughput_mode                 = "bursting"
  kms_key_id                      = var.efs_kms_key

  tags = {
    "Name" = var.deploy_id
  }
}

resource "aws_security_group" "efs" {
  name        = "${var.deploy_id}-efs"
  description = "EFS security group"
  vpc_id      = var.vpc_id

  lifecycle {
    create_before_destroy = true
  }
  tags = {
    "Name" = "${var.deploy_id}-efs"
  }
}

resource "aws_efs_mount_target" "eks" {
  count           = length(var.subnet_ids)
  file_system_id  = aws_efs_file_system.eks.id
  security_groups = [aws_security_group.efs.id]
  subnet_id       = element(var.subnet_ids, count.index)
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

    path = var.efs_access_point_path
  }
}
