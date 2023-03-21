output "info" {
  description = "Bastion information."
  value = {
    user                = var.bastion.username
    public_ip           = aws_eip.bastion.public_ip
    security_group_id   = aws_security_group.bastion.id
    ssh_bastion_command = "ssh -i ${var.ssh_key.path} -oUserKnownHostsFile=/dev/null -oStrictHostKeyChecking=no ${var.bastion.username}@${aws_eip.bastion.public_ip}"
  }
}


# output "security_group_id" {
#   description = "Bastion host security group id."
#   value       = aws_security_group.bastion.id
# }

# output "public_ip" {
#   description = "Bastion host public ip."
#   value       = aws_eip.bastion.public_ip
# }

# output "ssh_bastion_command" {
#   description = "Command to ssh into the bastion host"
#   value       = "ssh -i ${var.ssh_key.path} -oUserKnownHostsFile=/dev/null -oStrictHostKeyChecking=no ${var.bastion.username}@${aws_eip.bastion.public_ip}"
# }

# output "user" {
#   description = "Bastion host username"
#   value       = var.bastion.username
# }
