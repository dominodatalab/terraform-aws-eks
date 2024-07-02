data "aws_network_interface" "bastion" {
  filter {
    name   = "association.public-ip"
    values = [var.bastion_info.public_ip]
  }
}

resource "aws_route_table" "nat_instance" {
  route {
    cidr_block           = "0.0.0.0/0"
    network_interface_id = data.aws_network_interface.bastion.id
  }
  vpc_id = var.network_info.vpc_id
  tags = {
    "Name" = "${var.deploy_id}-nat",
  }
}

resource "aws_route_table_association" "nat" {
  for_each = merge(
    { for subnet in var.network_info.subnets.private : subnet.name => subnet.subnet_id },
    { for subnet in var.network_info.subnets.pod : subnet.name => subnet.subnet_id }
  )
  subnet_id      = each.value
  route_table_id = aws_route_table.nat_instance.id
}

resource "terraform_data" "nat_instance" {
  triggers_replace = var.bastion_info

  connection {
    type        = "ssh"
    user        = var.bastion_info.user
    private_key = file(var.ssh_key.path)
    host        = var.bastion_info.public_ip
  }

  provisioner "file" {
    source      = "${path.module}/files/nat.service"
    destination = "/tmp/nat.service"
  }

  provisioner "file" {
    source      = "${path.module}/files/nat.sh"
    destination = "/tmp/nat.sh"
  }

  provisioner "remote-exec" {
    inline = [
      "sudo mv /tmp/nat.service /etc/systemd/system/nat.service",
      "sudo mv /tmp/nat.sh /usr/local/bin/nat.sh",
      "sudo chmod +x /usr/local/bin/nat.sh",
      "sudo systemctl daemon-reload",
      "sudo systemctl enable --now nat",
    ]
  }
}

data "aws_subnet" "subnets" {
  for_each = merge(
    { for subnet in var.network_info.subnets.private : subnet.name => subnet.subnet_id },
    { for subnet in var.network_info.subnets.pod : subnet.name => subnet.subnet_id }
  )

  id = each.value
}

resource "aws_security_group_rule" "bastion_nat" {
  security_group_id = var.bastion_info.security_group_id

  protocol    = "-1"
  from_port   = "0"
  to_port     = "0"
  type        = "ingress"
  description = "Allow all ingress traffic from internal network"
  cidr_blocks = [
    for subnet_name, subnet in
    merge(
      { for subnet in var.network_info.subnets.private : subnet.name => data.aws_subnet.subnets[subnet.name] },
      { for subnet in var.network_info.subnets.pod : subnet.name => data.aws_subnet.subnets[subnet.name] }
    ) :
    subnet.cidr_block
  ]
}
