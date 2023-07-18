output "info" {
  description = "Nework information. vpc_id, subnets, target groups..."
  value = {
    vpc_id = local.create_vpc ? aws_vpc.this[0].id : data.aws_vpc.provided[0].id
    subnets = {
      public  = local.public_subnets
      private = local.private_subnets
      pod     = local.pod_subnets
    },
    target_groups = { for k, v in aws_lb_target_group.target_groups : k => v.arn }
  }
}
