output "security_group_id" {
  description = "Bastion host security group id."
  value       = aws_security_group.bastion.id
}

output "public_ip" {
  description = "Bastion host public ip."
  value       = aws_eip.bastion.public_ip
}

output "ssh_bastion_command" {
  description = "Command to ssh into the bastion host"
  value       = "ssh -i ${var.ssh_pvt_key_path} -oUserKnownHostsFile=/dev/null -oStrictHostKeyChecking=no ${var.bastion_user}@${aws_eip.bastion.public_ip}"
}

output "user" {
  description = "Bastion host username"
  value       = var.bastion_user
}
