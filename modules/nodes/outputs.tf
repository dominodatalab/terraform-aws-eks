output "info" {
  description = "Node and EKS addons details."
  value       = merge(aws_eks_node_group.node_groups, aws_eks_addon.pre_compute_addons, aws_eks_addon.post_compute_addons)
}
