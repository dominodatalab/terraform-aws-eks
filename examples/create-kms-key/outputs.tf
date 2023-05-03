output "kms_key_id" {
  description = "KMS key id"
  value       = aws_kms_key.custom.key_id
}
