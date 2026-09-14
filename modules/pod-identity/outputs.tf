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

output "filetask_objectstore_role_arn" {
  description = "ARN of the S3 Files task role, or null when filetask_objectstore is not enabled"
  value       = try(aws_iam_role.filetask_objectstore[0].arn, null)
}
