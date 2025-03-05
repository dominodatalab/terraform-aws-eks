resource "aws_efs_file_system" "eks" {
  count                           = local.deploy_efs ? 1 : 0
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
  count       = local.deploy_efs ? 1 : 0
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

resource "aws_efs_mount_target" "eks_cluster" {
  for_each        = local.deploy_efs ? { for sb in var.network_info.subnets.private : sb.name => sb } : {}
  file_system_id  = aws_efs_file_system.eks[0].id
  security_groups = [aws_security_group.efs[0].id]
  subnet_id       = each.value.subnet_id
}


resource "aws_efs_access_point" "eks" {
  count          = local.deploy_efs ? 1 : 0
  file_system_id = aws_efs_file_system.eks[0].id

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

moved {
  from = aws_efs_file_system.eks
  to   = aws_efs_file_system.eks[0]
}

moved {
  from = aws_security_group.efs
  to   = aws_security_group.efs[0]
}

moved {
  from = aws_efs_mount_target.eks
  to   = aws_efs_mount_target.eks[0]
}


removed {
  from = aws_efs_mount_target.eks

  lifecycle {
    destroy = false
  }
}
