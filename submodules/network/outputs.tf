
locals {

  public_subnets  = local.create_vpc ? [for cidr, c in local.public_cidrs : { name = c.name, subnet_id = aws_subnet.public[cidr].id, az = c.az, az_id = c.az_id }] : [for subnet in data.aws_subnet.public : { name = subnet.tags.Name, subnet_id = subnet.id, az = subnet.availability_zone, az_id = subnet.availability_zone_id }]
  private_subnets = local.create_vpc ? [for cidr, c in local.private_cidrs : { name = c.name, subnet_id = aws_subnet.private[cidr].id, az = c.az, az_id = c.az_id }] : [for subnet in data.aws_subnet.private : { name = subnet.tags.Name, subnet_id = subnet.id, az = subnet.availability_zone, az_id = subnet.availability_zone_id }]
  pod_subnets     = local.create_vpc ? [for cidr, c in local.pod_cidrs : { name = c.name, subnet_id = aws_subnet.pod[cidr].id, az = c.az, az_id = c.az_id }] : [for subnet in data.aws_subnet.pod : { name = subnet.tags.Name, subnet_id = subnet.id, az = subnet.availability_zone, az_id = subnet.availability_zone_id }]
}

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
