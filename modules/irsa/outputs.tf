output "roles" {
  description = "Roles mapping info"
  value       = { for k, v in aws_iam_role.this : k => v.arn }
}

output "external_dns" {
  description = "External_dns info"
  value = var.external_dns.enabled ? {
    irsa_role                = aws_iam_role.external_dns[0].arn
    zone_id                  = data.aws_route53_zone.hosted[0].zone_id
    zone_name                = data.aws_route53_zone.hosted[0].name
    external_dns_use_eks_idp = var.use_cluster_odc_idp
  } : null
}

output "netapp_trident_operator" {
  description = "NetApp Astra Trident FSX Operator role info"
  value = var.netapp_trident_operator.enabled ? {
    irsa_role = aws_iam_role.trident_operator[0].arn
  } : null
}

output "external_deployments_operator" {
  description = "External deployments operator role info"
  value = var.external_deployments_operator.enabled ? {
    irsa_role            = aws_iam_role.external_deployments_operator[0].arn
    service_account_name = var.external_deployments_operator.serviceaccount_name
  } : null
}
