output "vpc_id" {
  description = "VPC id."
  value       = local.vpc_id
}

output "public_subnets" {
  description = "List of public subnet ID and AZ"
  value       = [for cidr, c in local.public_cidrs : { name = c.name, subnet_id = aws_subnet.public[cidr].id, az = c.az, az_id = c.az_id }]
}

output "private_subnets" {
  description = "List of private subnet ID and AZ"
  value       = [for cidr, c in local.private_cidrs : { name = c.name, subnet_id = aws_subnet.private[cidr].id, az = c.az, az_id = c.az_id }]
}

output "pod_subnets" {
  description = "List of pod subnet ID and AZ"
  value       = [for cidr, c in local.pod_cidrs : { name = c.name, subnet_id = aws_subnet.pod[cidr].id, az = c.az, az_id = c.az_id }]
}
