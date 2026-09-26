output "info" {
  description = "Bastion information."
  value = {
    user = var.bastion.username
    # Air-gapped callers (e.g. an install node inside the same VPC) can use
    # the bastion's private IP instead of its public EIP for SSH/tunnel
    # access - toggle via var.bastion.use_private_ip_for_tunnel.
    public_ip           = var.bastion.use_private_ip_for_tunnel ? aws_instance.bastion.private_ip : aws_eip.bastion.public_ip
    security_group_id   = aws_security_group.bastion.id
    ssh_bastion_command = "ssh -i ${var.ssh_key.path} -oUserKnownHostsFile=/dev/null -oStrictHostKeyChecking=no ${var.bastion.username}@${var.bastion.use_private_ip_for_tunnel ? aws_instance.bastion.private_ip : aws_eip.bastion.public_ip}"
  }
}
