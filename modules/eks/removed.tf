removed {
  from = aws_eks_addon.vpc_cni
  lifecycle {
    destroy = false
  }
}
