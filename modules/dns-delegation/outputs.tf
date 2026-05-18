output "record_fqdn" {
  description = "FQDN of the NS delegation record."
  value       = aws_route53_record.this.fqdn
}

output "record_name" {
  description = "Name of the NS delegation record."
  value       = aws_route53_record.this.name
}
