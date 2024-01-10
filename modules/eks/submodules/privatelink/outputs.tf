output "info" {
  description = "Target groups..."
  value = {
    target_groups = { for k, v in aws_lb_target_group.target_groups : k => v.arn }
    nlbs = { arns : { for k, nlb in aws_lb.nlbs : k => {
      arn      = nlb.arn
      dns_name = nlb.dns_name
      zone_id  = nlb.zone_id
    } } }
    nlb_sg = aws_security_group.nlb_sg.id
  }
}
