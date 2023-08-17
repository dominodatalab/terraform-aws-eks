output "infra" {
  description = "Infra details."
  value       = local.infra
}

output "eks" {
  description = "EKS details."
  value       = module.eks.info
}
