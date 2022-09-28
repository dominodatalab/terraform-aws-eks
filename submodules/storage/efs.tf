resource "aws_efs_file_system" "eks" {
  encrypted                       = true
  performance_mode                = "generalPurpose"
  provisioned_throughput_in_mibps = "0"
  throughput_mode                 = "bursting"

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

resource "aws_security_group_rule" "efs" {
  security_group_id = aws_security_group.efs.id
  protocol          = "tcp"
  from_port         = 2049
  to_port           = 2049
  type              = "ingress"
  description       = "EFS access"
  cidr_blocks       = [for s in var.subnets : s.cidr_block]
}

resource "aws_efs_mount_target" "eks" {
  for_each        = var.subnets
  file_system_id  = aws_efs_file_system.eks.id
  security_groups = [aws_security_group.efs.id]
  subnet_id       = each.value.id
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
