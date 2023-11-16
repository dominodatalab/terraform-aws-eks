output "info" {
  description = "Target groups..."
  value = {
    target_groups = { for k, v in aws_lb_target_group.target_groups : k => v.arn }
    nlbs          = { arns : [for k, nlb in aws_lb.nlbs : nlb.arn] }
  }
}
