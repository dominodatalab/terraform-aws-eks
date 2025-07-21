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
  value       = var.storage != null ? module.storage.info : null
}

output "tags" {
  description = "Deployment tags."
  value       = var.tags
}

output "deploy_id" {
  description = "Domino Deployment ID."
  value       = var.deploy_id
}

output "ignore_tags" {
  description = "Tags to be ignored by the aws provider"
  value       = var.ignore_tags
}

output "region" {
  description = "Deployment Region."
  value       = var.region
}

output "eks" {
  description = "EKS variables."
  value       = var.eks
}

output "ssh_key" {
  description = "SSH key path,name."
  value       = local.ssh_key
}

output "additional_node_groups" {
  description = "Additional EKS managed node groups definition."
  value       = var.additional_node_groups
}

output "default_node_groups" {
  description = "Default nodegroups."
  value       = var.default_node_groups
}

output "node_iam_policies" {
  description = "Policies attached to EKS nodes role"
  value       = local.node_iam_policies
}

output "create_eks_role_arn" {
  description = "Role arn to assume during the EKS cluster creation."
  value       = aws_iam_role.create_eks_role.arn
}

output "monitoring_bucket" {
  description = "Monitoring Bucket"
  value       = try(module.storage.info.s3.buckets.monitoring.bucket_name, null)
}

output "cost_usage_report" {
  description = "Cost Usage Report"
  value       = local.cost_usage_report_info
}

output "vpn_connections" {
  description = "VPN connection information"
  value       = var.vpn_connections.create ? module.vpn[0].vpn_connections : null
}
