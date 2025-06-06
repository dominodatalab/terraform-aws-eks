output "info" {
  description = "Load Balancers Info"
  value = {
    lb_target_groups = { for k, v in aws_lb_target_group.lb_target_groups : k => v.arn }
  }
}
