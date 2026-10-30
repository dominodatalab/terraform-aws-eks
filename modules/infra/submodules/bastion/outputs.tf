output "info" {
  description = "Bastion information."
  value = {
    user = var.bastion.username
    # Air-gapped callers (e.g. an install node inside the same VPC) can use
    # the bastion's private IP instead of a public EIP for SSH/tunnel
    # access - toggle via var.bastion.use_private_ip_for_tunnel (no EIP is
    # created when set).
    public_ip           = local.bastion_host_ip
    security_group_id   = aws_security_group.bastion.id
    ssh_bastion_command = "ssh -i ${var.ssh_key.path} -oUserKnownHostsFile=/dev/null -oStrictHostKeyChecking=no ${var.bastion.username}@${local.bastion_host_ip}"
  }
}
