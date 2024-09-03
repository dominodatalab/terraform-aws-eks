output "info" {
  description = "Nework information. vpc_id, subnets..."
  value = {
    az_ids = local.az_ids
    vpc_id = local.create_vpc ? aws_vpc.this[0].id : data.aws_vpc.provided[0].id
    subnets = {
      public  = local.public_subnets
      private = local.private_subnets
      pod     = local.pod_subnets
    }
    route_tables = {
      public  = [for rt in aws_route_table.public : rt.id]
      private = [for rt in aws_route_table.private : rt.id]
      pod     = [for rt in aws_route_table.pod : rt.id]
    }
    eips      = [for k, eip in aws_eip.public : eip.public_ip]
    vpc_cidrs = var.network.cidrs.vpc
  }
}
