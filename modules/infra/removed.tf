removed {
  from = aws_iam_policy.route53
  lifecycle {
    destroy = false
  }
}
