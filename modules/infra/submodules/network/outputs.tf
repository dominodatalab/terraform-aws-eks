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
      public  = local.public_route_table_ids
      private = local.private_route_table_ids
      pod     = local.pod_route_table_ids
    }
    eips      = [for k, eip in aws_eip.public : eip.public_ip]
    vpc_cidrs = var.network.cidrs.vpc
    s3_cidr = data.aws_prefix_list.s3.cidr_blocks
  }
}
