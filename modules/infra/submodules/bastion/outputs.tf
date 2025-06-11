output "info" {
  description = "Bastion information."
  value = {
    user                 = var.bastion.username
    public_ip            = aws_eip.bastion.public_ip
    security_group_id    = aws_security_group.bastion.id
    ssh_bastion_command  = "ssh -i ${var.ssh_key.path} -oUserKnownHostsFile=/dev/null -oStrictHostKeyChecking=no ${var.bastion.username}@${aws_eip.bastion.public_ip}"
    instance_id          = aws_instance.bastion.id
    use_instance_connect = var.bastion.use_instance_connect
  }
}
