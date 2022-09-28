output "vpc_id" {
  description = "VPC id."
  value       = local.vpc_id
}

output "private_subnets" {
  description = "Private subnets object."
  value       = aws_subnet.private
}

output "public_subnets" {
  description = "Public subnets object."
  value       = aws_subnet.public
}
