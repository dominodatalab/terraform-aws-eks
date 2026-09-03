data "aws_partition" "current" {}

data "aws_ami" "fck_nat" {
  count       = local.create_fck_nat && var.network.nat.ami_id == null ? 1 : 0
  most_recent = true
  owners      = ["568608671756"]

  filter {
    name   = "name"
    values = ["fck-nat-al2023-*-arm64-ebs"]
  }

  filter {
    name   = "architecture"
    values = ["arm64"]
  }
}

locals {
  create_fck_nat = !local.use_managed_nat && local.create_vpc
  fck_nat_ami_id = local.create_fck_nat ? coalesce(var.network.nat.ami_id, one(data.aws_ami.fck_nat[*].id)) : null
}

resource "aws_security_group" "fck_nat" {
  count                  = local.create_fck_nat ? 1 : 0
  name                   = "${var.deploy_id}-fck-nat"
  description            = "fck-nat instance security group"
  revoke_rules_on_delete = true
  vpc_id                 = aws_vpc.this[0].id

  lifecycle {
    create_before_destroy = true
  }

  tags = {
    "Name" = "${var.deploy_id}-fck-nat"
  }
}

resource "aws_security_group_rule" "fck_nat_ingress_vpc" {
  count             = local.create_fck_nat ? 1 : 0
  security_group_id = aws_security_group.fck_nat[0].id
  type              = "ingress"
  protocol          = "-1"
  from_port         = 0
  to_port           = 0
  cidr_blocks       = [aws_vpc.this[0].cidr_block]
  description       = "Allow all traffic from VPC CIDR"
}

resource "aws_security_group_rule" "fck_nat_ingress_pod" {
  count             = local.create_fck_nat && var.network.use_pod_cidr ? 1 : 0
  security_group_id = aws_security_group.fck_nat[0].id
  type              = "ingress"
  protocol          = "-1"
  from_port         = 0
  to_port           = 0
  cidr_blocks       = [var.network.cidrs.pod]
  description       = "Allow all traffic from pod CIDR"
}

resource "aws_security_group_rule" "fck_nat_egress" {
  count             = local.create_fck_nat ? 1 : 0
  security_group_id = aws_security_group.fck_nat[0].id
  type              = "egress"
  protocol          = "-1"
  from_port         = 0
  to_port           = 0
  description       = "Allow all outbound traffic"
  # trivy:ignore:AVD-AWS-0104 NAT instance requires unrestricted egress to forward traffic
  cidr_blocks = ["0.0.0.0/0"]
}

data "aws_iam_policy_document" "fck_nat" {
  count = local.create_fck_nat ? 1 : 0

  statement {
    actions = ["sts:AssumeRole"]

    principals {
      type        = "Service"
      identifiers = ["ec2.${data.aws_partition.current.dns_suffix}"]
    }
  }
}

resource "aws_iam_role" "fck_nat" {
  count              = local.create_fck_nat ? 1 : 0
  name               = "${var.deploy_id}-fck-nat"
  assume_role_policy = data.aws_iam_policy_document.fck_nat[0].json

  tags = {
    "Name" = "${var.deploy_id}-fck-nat"
  }
}

resource "aws_iam_role_policy_attachment" "fck_nat_ssm" {
  count      = local.create_fck_nat ? 1 : 0
  policy_arn = "arn:${data.aws_partition.current.partition}:iam::aws:policy/AmazonSSMManagedInstanceCore"
  role       = aws_iam_role.fck_nat[0].name
}

resource "aws_iam_instance_profile" "fck_nat" {
  count = local.create_fck_nat ? 1 : 0
  name  = "${var.deploy_id}-fck-nat"
  role  = aws_iam_role.fck_nat[0].name
}

resource "aws_instance" "fck_nat" {
  for_each             = local.create_fck_nat ? local.public_cidrs : {}
  ami                  = local.fck_nat_ami_id
  instance_type        = var.network.nat.instance_type
  subnet_id            = aws_subnet.public[each.key].id
  source_dest_check    = false
  iam_instance_profile = aws_iam_instance_profile.fck_nat[0].name

  metadata_options {
    http_endpoint               = "enabled"
    http_put_response_hop_limit = 1
    http_tokens                 = "required"
    instance_metadata_tags      = "disabled"
  }

  root_block_device {
    delete_on_termination = true
    encrypted             = true
    volume_type           = "gp3"
    iops                  = 3000
    throughput            = 125
    tags = {
      "Name" = "${var.deploy_id}-fck-nat-${each.value.az}"
    }
  }

  vpc_security_group_ids = [aws_security_group.fck_nat[0].id]

  tags = {
    "Name" = "${var.deploy_id}-fck-nat-${each.value.az}"
  }
}

resource "aws_eip_association" "fck_nat" {
  for_each      = local.create_fck_nat ? local.public_cidrs : {}
  instance_id   = aws_instance.fck_nat[each.key].id
  allocation_id = aws_eip.public[each.key].allocation_id
}
