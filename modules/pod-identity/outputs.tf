output "roles" {
  description = "Roles mapping info, keyed by config name"
  value       = { for k, v in aws_iam_role.this : k => v.arn }
}

output "associations" {
  description = "Pod identity associations, keyed by config name"
  value = { for k, v in aws_eks_pod_identity_association.this : k => {
    association_arn = v.association_arn
    association_id  = v.association_id
    namespace       = v.namespace
    service_account = v.service_account
  } }
}
