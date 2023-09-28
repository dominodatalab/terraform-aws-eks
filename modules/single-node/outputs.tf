output "info" {
  description = "Node details."
  value = {
    private_ip           = aws_instance.single_node.private_ip
    ami                  = aws_instance.single_node.ami
    id                   = aws_instance.single_node.id
    public_ip            = aws_eip.single_node.public_ip
    instance_type        = aws_instance.single_node.instance_type
    iam_instance_profile = aws_instance.single_node.iam_instance_profile
    subnet_id            = aws_instance.single_node.subnet_id
    key_name             = aws_instance.single_node.key_name
  }
}
