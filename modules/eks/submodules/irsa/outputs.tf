output "roles" {
  description = "Roles mapping info"
  value       = { for k, v in aws_iam_role.this : k => v.arn }
}

output "external_dns" {
  description = "External_dns info"
  value = var.external_dns.enabled ? {
    irsa_role = aws_iam_role.external_dns[0].arn
    zone_id   = data.aws_route53_zone.hosted[0].zone_id
    zone_name = data.aws_route53_zone.hosted[0].name
  } : null
}
