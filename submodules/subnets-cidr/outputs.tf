output "public_subnets" {
  description = "Map containing the CIDR information for the public subnets"
  value       = local.public_subnets
}

output "private_subnets" {
  description = "Map containing the CIDR information for the private subnets"
  value       = local.private_subnets
}
