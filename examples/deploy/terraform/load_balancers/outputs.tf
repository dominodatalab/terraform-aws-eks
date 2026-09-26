output "load_balancers" {
  description = "Load balancer details (ARNs, target groups)."
  value       = try(module.load_balancers[0].info, null)
}

output "privatelink" {
  description = "PrivateLink details."
  value       = try(module.privatelink[0], null)
}
