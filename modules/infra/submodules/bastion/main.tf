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
  vpc_id                 = var.network_info.vpc_id

  lifecycle {
    create_before_destroy = true
    ignore_changes        = [description]
  }

  tags = {
    "Name" = "${var.deploy_id}-bastion"
  }
}

resource "aws_security_group_rule" "bastion_outbound" {
  security_group_id = aws_security_group.bastion.id

  protocol    = "-1"
  from_port   = "0"
  to_port     = "0"
  type        = "egress"
  description = "Allow all outbound traffic by default"
  cidr_blocks = ["0.0.0.0/0"]
}

locals {
  security_group_rules = {
    bastion_inbound_ssh = {
      protocol                 = "tcp"
      from_port                = "22"
      to_port                  = "22"
      type                     = "ingress"
      description              = "Inbound ssh"
      cidr_blocks              = var.bastion.authorized_ssh_ip_ranges
      source_security_group_id = null
    }
  }
}
resource "aws_security_group_rule" "bastion" {
  for_each = local.security_group_rules

  security_group_id        = aws_security_group.bastion.id
  protocol                 = each.value.protocol
  from_port                = each.value.from_port
  to_port                  = each.value.to_port
  type                     = each.value.type
  description              = each.value.description
  cidr_blocks              = try(each.value.cidr_blocks, null)
  source_security_group_id = try(each.value.source_security_group_id, null)
}

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

resource "terraform_data" "check_bastion_instance_profile" {
  provisioner "local-exec" {
    command     = <<-EOF
      set -x -o pipefail

      sleep_duration=10
      iam_profile="${aws_iam_instance_profile.bastion.name}"

      check_iam_profile() {
        echo "Checking for $iam_profile ..."
        aws iam get-instance-profile --instance-profile-name $iam_profile > /dev/null 2>&1
      }

      for _ in {1..30}; do
        if check_iam_profile; then
          exit 0
        fi

        sleep "$sleep_duration"
      done

      echo "Timeout reached waiting for $iam_profile ...Exiting"
      exit 1
    EOF
    interpreter = ["bash", "-c"]
    environment = {
      AWS_USE_FIPS_ENDPOINT = tostring(var.use_fips_endpoint)
    }
  }
  depends_on = [aws_iam_instance_profile.bastion]
}

data "aws_ami" "al2023" {
  count       = var.bastion.ami_id == null ? 1 : 0
  most_recent = true
  owners      = ["amazon"]

  filter {
    name   = "name"
    values = ["al2023-ami*"]
  }

  filter {
    name   = "architecture"
    values = ["x86_64"]
  }
}

locals {
  ami_id = var.bastion.ami_id != null ? var.bastion.ami_id : data.aws_ami.al2023[0].id
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
  instance_type                        = var.bastion.instance_type != null ? var.bastion.instance_type : "t3.micro"
  key_name                             = var.ssh_key.key_pair_name

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
    kms_key_id            = var.kms_info.enabled ? var.kms_info.key_arn : null
    tags = {
      "Name" = "${var.deploy_id}-bastion"
    }
  }

  source_dest_check = true
  subnet_id         = var.network_info.subnets.public[0].subnet_id

  vpc_security_group_ids = [aws_security_group.bastion.id]
  tags = {
    "Name" = "${var.deploy_id}-bastion"
  }
  lifecycle {
    ignore_changes = [
      root_block_device[0].tags,
      root_block_device[0].kms_key_id,
    ]
  }
  depends_on = [terraform_data.check_bastion_instance_profile]
}

resource "aws_eip" "bastion" {
  instance             = aws_instance.bastion.id
  network_border_group = var.region
  domain               = "vpc"
}

resource "aws_eip_association" "bastion" {
  instance_id   = aws_instance.bastion.id
  allocation_id = aws_eip.bastion.id
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

resource "null_resource" "install_binaries" {
  count = var.bastion.install_binaries ? 1 : 0

  connection {
    type        = "ssh"
    user        = var.bastion.username
    private_key = file(var.ssh_key.path)
    host        = self.triggers.bastion_elastic_ip
  }

  provisioner "remote-exec" {
    inline = [
      "sudo cloud-init status --wait || sleep 60",
    ]
  }

  provisioner "file" {
    content = templatefile("${path.module}/templates/install-binaries.sh.tftpl", {
      k8s_version  = var.k8s_version
      bastion_user = var.bastion.username
    })
    destination = self.triggers.sh_filepath
  }

  provisioner "remote-exec" {
    inline = [
      "chmod +x ${self.triggers.sh_filepath}",
      "LOG_FILE=$HOME/binaries-install-$(date +%Y_%m_%d-%H_%M).log",
      "sudo ${self.triggers.sh_filepath} > $LOG_FILE 2>&1",
      "rm -f ${self.triggers.sh_filepath}",
    ]
  }


  triggers = {
    sh_filepath = "/home/${var.bastion.username}/install-binaries.sh"
    sh_content_hash = md5(templatefile("${path.module}/templates/install-binaries.sh.tftpl", {
      k8s_version  = var.k8s_version
      bastion_user = var.bastion.username
    }))
    bastion_elastic_ip = aws_eip.bastion.public_ip
  }

  depends_on = [
    aws_instance.bastion,
    aws_eip_association.bastion
  ]
}
