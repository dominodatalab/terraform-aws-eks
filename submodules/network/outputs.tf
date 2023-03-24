output "info" {
  description = "Nework information. vpc_id, subnets..."
  value = {
    vpc_id = local.create_vpc ? aws_vpc.this[0].id : data.aws_vpc.provided[0].id
    subnets = {
      public  = local.public_subnets
      private = local.private_subnets
      pod     = local.pod_subnets
    }
  }
}
