output "hostname" {
  description = "Domino instance URL."
  value       = try("${var.deploy_id}.${var.route53_hosted_zone_name}", null)
}
output "domino_key_pair" {
  description = "Domino key pair"
  value       = { name = aws_key_pair.domino.key_name }
}

output "kms" {
  description = "KMS key details, if enabled."
  value       = local.kms_info
}

output "network" {
  description = "Network details."
  value       = module.network.info
}

output "bastion" {
  description = "Bastion details, if it was created."
  value       = local.bastion_info
}

output "storage" {
  description = "Storage details."
  value       = module.storage.info
}

output "eks" {
  description = "EKS details."
  value       = module.eks.info
}
