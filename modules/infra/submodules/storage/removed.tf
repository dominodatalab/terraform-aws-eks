removed {
  from = aws_efs_mount_target.eks

  lifecycle {
    destroy = false
  }
}
