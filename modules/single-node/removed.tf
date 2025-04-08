removed {
  from = aws_eks_addon.this
  lifecycle {
    destroy = false
  }
}
