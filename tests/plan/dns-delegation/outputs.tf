output "record_fqdn" {
  description = "FQDN of the NS delegation record."
  value       = module.dns_delegation.record_fqdn
}

output "record_name" {
  description = "Name of the NS delegation record."
  value       = module.dns_delegation.record_name
}
