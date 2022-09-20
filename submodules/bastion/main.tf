data "aws_partition" "current" {}
data "aws_caller_identity" "aws_account" {}

locals {
  dns_suffix     = data.aws_partition.current.dns_suffix
  aws_account_id = data.aws_caller_identity.aws_account.account_id
}

resource "aws_security_group" "bastion" {
  name                   = "${var.deploy_id}-bastion"
  description            = "Bastion security group"
  revoke_rules_on_delete = true
  vpc_id                 = var.vpc_id

  lifecycle {
    create_before_destroy = true
    ignore_changes = [description]
  }

  tags = {
    "Name" = "${var.deploy_id}-bastion"
  }
}
resource "aws_security_group_rule" "bastion" {
  for_each = var.security_group_rules

  security_group_id        = aws_security_group.bastion.id
  protocol                 = each.value.protocol
  from_port                = each.value.from_port
  to_port                  = each.value.to_port
  type                     = each.value.type
  description              = each.value.description
  cidr_blocks              = try(each.value.cidr_blocks, null)
  source_security_group_id = try(each.value.source_security_group_id, null)
}
## Bastion iam role
data "aws_iam_policy_document" "bastion" {
  statement {
    actions = ["sts:AssumeRole"]

    principals {
      type        = "Service"
      identifiers = ["ec2.${local.dns_suffix}"]
    }
  }

  statement {
    effect  = "Allow"
    actions = ["sts:AssumeRole"]

    principals {
      type        = "AWS"
      identifiers = ["arn:${data.aws_partition.current.partition}:iam::${local.aws_account_id}:root"]
    }
  }
}

resource "aws_iam_role" "bastion" {
  assume_role_policy = data.aws_iam_policy_document.bastion.json
  name               = "${var.deploy_id}-bastion"
  tags = {
    "Name" = "${var.deploy_id}-bastion"
  }
}

resource "aws_iam_role_policy_attachment" "bastion" {
  policy_arn = "arn:${data.aws_partition.current.partition}:iam::aws:policy/AmazonSSMManagedInstanceCore"
  role       = aws_iam_role.bastion.name
}

resource "aws_iam_instance_profile" "bastion" {
  name = "${var.deploy_id}-bastion"
  role = aws_iam_role.bastion.name
}

data "aws_ami" "amazon_linux_2" {
  count       = var.ami_id == null ? 1 : 0
  most_recent = true
  owners      = ["amazon"]

  filter {
    name   = "name"
    values = ["amzn2-ami-hvm*"]
  }

  filter {
    name   = "architecture"
    values = ["x86_64"]
  }
}

locals {
  ami_id = var.ami_id != null ? var.ami_id : data.aws_ami.amazon_linux_2[0].id
}

resource "aws_instance" "bastion" {
  ami                         = local.ami_id
  associate_public_ip_address = true
  iam_instance_profile        = aws_iam_instance_profile.bastion.name
  monitoring                  = true

  capacity_reservation_specification {
    capacity_reservation_preference = "open"
  }

  disable_api_termination = false
  ebs_optimized           = false

  enclave_options {
    enabled = false
  }

  get_password_data                    = false
  hibernation                          = false
  instance_initiated_shutdown_behavior = "stop"
  instance_type                        = var.instance_type != null ? var.instance_type : "t2.micro"
  key_name                             = var.ssh_pvt_key_path

  metadata_options {
    http_endpoint               = "enabled"
    http_put_response_hop_limit = "1"
    http_tokens                 = "required"
    instance_metadata_tags      = "disabled"
  }

  root_block_device {
    delete_on_termination = true
    encrypted             = true
    iops                  = "3000"
    throughput            = "125"
    volume_size           = "40"
    volume_type           = "gp3"
  }

  source_dest_check = true
  subnet_id         = var.public_subnet_id

  vpc_security_group_ids = [aws_security_group.bastion.id]
  tags = {
    "Name" = "${var.deploy_id}-bastion"
  }
  lifecycle {
    ignore_changes = [
      root_block_device[0].tags,
    ]
  }
}

resource "aws_eip" "bastion" {
  instance             = aws_instance.bastion.id
  network_border_group = var.region
  vpc                  = true
}

data "aws_iam_policy_document" "bastion_assume_role" {
  statement {

    effect    = "Allow"
    resources = [aws_iam_role.bastion.arn]
    actions   = ["sts:AssumeRole"]
  }
}

resource "aws_iam_policy" "bastion_assume_role" {
  name = "${var.deploy_id}-bastion-assume"

  description = "Allows bastion to assume a role"
  policy      = data.aws_iam_policy_document.bastion_assume_role.json
}


resource "aws_iam_role_policy_attachment" "bastion_assume_role" {
  policy_arn = aws_iam_policy.bastion_assume_role.arn
  role       = aws_iam_role.bastion.name
}
