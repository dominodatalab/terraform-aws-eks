output "infra" {
  description = "Infra details."
  value       = local.infra
}

output "eks" {
  description = "EKS details."
  value       = module.eks.info
}

output "external_dns_irsa_role_arn" {
  description = <<EOF
  "External_dns info"
  {
    irsa_role = irsa role arn.
    zone_id   = hosted zone id for external_dns Iam policy
    zone_name = hosted zone name for external_dns Iam policy
  }
  EOF
  value       = module.irsa_external_dns
}

output "external_deployments_operator" {
  description = "External deployments operator details."
  value       = try(module.external_deployments_operator[0], null)
}

output "flyte" {
  description = "Flyte details."
  value       = try(module.flyte[0], null)
}
